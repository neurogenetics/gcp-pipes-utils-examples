workflow TElocalWorkflow {
	
  	String dockerimg
  	
  	String sample_name
	
	File sample_bam_file
	
	call TElocal {
		input:
			sample_bam = sample_bam_file,
			output_name = sample_name,
			dockerimg = dockerimg
	}
	
	output {
		Array[File] retain_TElocal_output = TElocal.TElocal_output
		
	}
}

task TElocal {
	File sample_bam
	
	String output_name
	
	String stranded
	String cpus
	String dockerimg
	String mem_size
	Int disk_size
	Int preemptible_tries
	
	command <<<
        TElocal -b ${sample_bam} --GTF /annotations/hg38_gene_annotation.gtf --TE /annotations/hg38_rmsk_wHSAT2_TElocus.ind --project ${output_name} --stranded ${stranded}
	>>>
	
	runtime {
		docker: dockerimg
		memory: mem_size
		cpu: cpus
    	disks: "local-disk " + disk_size + " HDD"
    	preemptible: preemptible_tries
	}
	
	
	output {
  		Array[File] TElocal_output = glob("${output_name}*")
	}
	
}