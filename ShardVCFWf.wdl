##assumes the vcf in the set is only composed of variants from a single chromosome

##test local
##wget https://github.com/broadinstitute/cromwell/releases/download/36/cromwell-36.jar
##java -jar Cromwell.jar run ShardVCFSetWf.wdl --inputs ShardVCFWf.inputs.json

# WORKFLOW DEFINITION
workflow ShardVCFWf {

	File intervals_list_bed
	File input_vcf
	File input_vcf_index
	String basename_prefix

	String? lng_docker_override
	String lng_docker = select_first([lng_docker_override, "us.gcr.io/nih-nia-lng-cbg/shardvcfset:2018-1 "])
	Int? preemptible_attempts
	Int preemtptible_tries = select_first([preemptible_attempts, 3])

	Array[Array[String]] intervals = read_tsv(intervals_list_bed)

	scatter (interval in intervals) {
		call SubsetVCF {
			input:
				vcf = input_vcf,
				vcf_index = input_vcf_index,
				chromosome = interval[0],
				start_bp = interval[1],
				end_bp = interval[2],
				out_vcf_name = basename_prefix + "_" + interval[0] + "_" + interval[1] + "_" + interval[2] + ".vcf.gz",

				docker = lng_docker,
				preemtptible_tries = preemtptible_tries
		}
	}

	output {
    Array[File] output_vcfs = SubsetVCF.out_vcf
		Array[File] output_vcf_indices = SubsetVCF.out_vcf_index
  }
}


task SubsetVCF {
	File vcf
	File vcf_index
	String chromosome
	Int start_bp
	Int end_bp
	String out_vcf_name

	# Runtime parameters
	String docker
	Int preemtptible_tries
  Int? disk_space_gb
  Int? machine_mem_gb
	Int? machine_cpus

	command {
		set -eu

		bcftools view --threads $(nproc) --regions ${chromosome}:${start_bp}-${end_bp} --output-file ${out_vcf_name} --output-type z ${vcf}

		tabix -p vcf ${out_vcf_name}
	}
	output {
		File out_vcf = "${out_vcf_name}"
		File out_vcf_index = "${out_vcf_name}.tbi"
	}
	runtime {
		docker: docker
		memory: select_first([machine_mem_gb, 3]) + " GB"
    cpu: select_first([machine_cpus, 1])
    disks: "local-disk " + select_first([disk_space_gb, 200]) + " HDD"
		preemptible: preemtptible_tries
	}
}


task SplitIntervalsByChromosome {
	File intervals
	Array[String] chromosome_list

	command {
		python << CODE
		import pandas as pd

		df = pd.read_table(${intervals},sep='\t',header=None)
		df.columns = ['chr','start','stop']
		# Return number of columns and rows of dataframe
		df.shape
		df.head()
		#save genome bed as individual chromosome beds
		chromosomes = df["chr"].unique().tolist()
		outputFiles = []
		for thisChr in chromosomes:
		    outfile = thisChr + "_inervals.bed"
		    df[df["chr"] == thisChr].to_csv(outfile,sep="\t",index=False,header=False)
		    outputFiles.append(outfile)

		print(outputFiles)
		CODE
	}
	output {
		Array[File] interval_beds = glob("*_inervals.bed")
	}
}
