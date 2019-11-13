workflow TEtranscriptsWorkflow {
	
	
	File firstPairedEnd
	File secondPairedEnd
	
  	String dockerimg
  	
  	String sample_name
	
	File refgenomeFile
	
	File gene_annotation_gtf
	
	File TE_annotation_gtf
	

	
	call STARMap {
		input:
			fastq_1 = firstPairedEnd,
			fastq_2 = secondPairedEnd,
			refgenome = refgenomeFile,
			output_name = sample_name,
			dockerimg = dockerimg
	}
	
	call TEcount {
		input:
			sample_bam = STARMap.star_bam_output[0],
			gene_annotation = gene_annotation_gtf,
			TE_annotation = TE_annotation_gtf,
			output_name = sample_name,
			dockerimg = dockerimg
	}
	
	output {
		Array[File] retain_TEcount_output = TEcount.TEcount_output
		
	}
}

task STARMap {
	File fastq_1
	File fastq_2
	
	File refgenome
	
	Int disk_size
  	String mem_size
  	String dockerimg

  	Int preemptible_tries
  
  	String output_name
	
	command <<<
		tar -zxvf ${refgenome}
		STAR --genomeDir ref/ --runThreadN 32 --readFilesIn ${fastq_1} ${fastq_2} --winAnchorMultimapNmax 100 --outFilterMultimapNmax 100 --outSAMtype BAM Unsorted --outFileNamePrefix ${output_name} --readFilesCommand gunzip -c
	>>>
	
	runtime {
    	docker: dockerimg
    	memory: mem_size
    	cpu: "16"
    	disks: "local-disk " + disk_size + " HDD"
    	preemptible: preemptible_tries
	}
	
	output {
		Array[File] star_bam_output = glob("*.bam")
	}
}

task TEcount {
	File sample_bam
	
	File gene_annotation
	
	File TE_annotation
	
	String output_name
	
	String dockerimg
	String mem_size
	Int disk_size
	Int preemptible_tries
	
	command <<<
		TEcount -b ${sample_bam} --GTF ${gene_annotation} --TE ${TE_annotation} --project ${output_name}
	>>>
	
	runtime {
		docker: dockerimg
		memory: mem_size
		cpu: "32"
    	disks: "local-disk " + disk_size + " HDD"
    	preemptible: preemptible_tries
	}
	
	
	output {
  		Array[File] TEcount_output = glob("${output_name}*")
	}
	
}