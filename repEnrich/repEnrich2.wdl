workflow RepEnrichWorkflow {
	
	
	String sample_name
	File firstPairedEnd
	File secondPairedEnd
	
	Array[File] refgenomeFile
	
	File setup_zip
	
	
	call BowtieMap {
		input:
			fastq_1 = firstPairedEnd,
			fastq_2 = secondPairedEnd,
			refgenome = refgenomeFile
			
			
	}
	
	call SamToBam {
		input:
			input_sam = BowtieMap.bowtie_sam_output
	}
	
	call RepEnrich2Subset {
		input:
			input_bam = SamToBam.convert_bam_output,
			sample_name = sample_name
	}
	
	call RepEnrich2 {
		input:
			setup_hg38_zip = setup_zip,
			sample_name = sample_name,
			input_r1 = RepEnrich2Subset.R1_output[0],
			input_r2 = RepEnrich2Subset.R2_output[0],
			unique_bam = RepEnrich2Subset.bam_output[0]
	}
	
	output {
		Array[File] retain_RepEnrich2_output = RepEnrich2.repEnrich2_output
	}
}


task BowtieMap {
  File fastq_1
  File fastq_2
  
  Array[File] refgenome

  Int disk_size
  String mem_size
  String dockerimg

  Int preemptible_tries
  
  String output_name

  command <<<
  
  	bowtie2 -q -p 16 -x ${sub(refgenome[0],".fa","")} -1 ${fastq_1} -2 ${fastq_2} -S ${output_name}.sam

  >>>
  runtime {
    docker: dockerimg
    memory: mem_size
    cpu: "16"
    disks: "local-disk " + disk_size + " HDD"
    preemptible: preemptible_tries
  }
  
  output {
  	File bowtie_sam_output = "${output_name}.sam"
  }
}

task SamToBam {
	File input_sam
	String output_name
	
	String dockerimg
	String mem_size
	Int disk_size
	Int preemptible_tries
	
	command <<<
		samtools view -bS ${input_sam} > ${output_name}.bam
	>>>
	
	runtime {
    	docker: dockerimg
    	memory: mem_size
    	cpu: "2"
    	disks: "local-disk " + disk_size + " HDD"
    	preemptible: preemptible_tries
  	}
  	
  	output {
  		File convert_bam_output = "${output_name}.bam"
  	}
}

task RepEnrich2Subset {

	String dockerimg
	String mem_size
	Int disk_size
	Int preemptible_tries
	
	File python_script
	File input_bam
	
	Int mapq = 30
	
	String sample_name
	
	
	command <<<
		python ${python_script} ${input_bam} ${mapq} ${sample_name} --pairedend TRUE
	>>>
	
	runtime {
	    docker: dockerimg
    	memory: mem_size
    	cpu: "2"
    	disks: "local-disk " + disk_size + " HDD"
    	preemptible: preemptible_tries
	
	}
	
	output {
		Array[File] R1_output = glob("*_multimap_R1.fastq")
		Array[File] R2_output = glob("*_multimap_R2.fastq")
		Array[File] bam_output = glob("*.bam")
	}
	
}

task RepEnrich2 {

	String dockerimg
	String mem_size
	Int disk_size
	Int preemptible_tries
	
	File python_script
	File annotation_text
	
	String output_dir
	
	String sample_name
	
	File input_r1
	File input_r2
	
	File unique_bam
	
	File setup_hg38_zip
	
	String dollar = "$"
	
	command <<<
		mkdir -p ${dollar}{TMPDIR}/rep_output
		tar -zxvf ${setup_hg38_zip} -C ${dollar}{TMPDIR}
		python ${python_script} ${annotation_text} ${dollar}{TMPDIR}/rep_output ${sample_name} ${dollar}{TMPDIR}/setup_folder_hg38_cleaned/ ${input_r1} --fastqfile2 ${input_r2} ${unique_bam} --cpus 32 --pairedend TRUE
	>>>
	
	runtime {
	    docker: dockerimg
    	memory: mem_size
    	cpu: "32"
    	disks: "local-disk " + disk_size + " HDD"
    	preemptible: preemptible_tries
	
	}
	
	output {
  		Array[File] repEnrich2_output = glob("${dollar}{TMPDIR}/rep_output/*")
	}
	
}