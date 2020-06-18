##Run MELTv2.2.0 Singe and Deletion from .cram files
workflow MELTSingleDelFlow {
    File ref_fasta
    File ref_fasta_index
    File ref_dict
    File input_cram
    File input_cram_crai
    File region_bed
    File prior_files
    String sample_name
    String meltv2_docker
    Int preemptible_tries

  #convert .cram to .bam with filtering applied
  call CramToBamTask{	
    input:
      ref_fasta = ref_fasta,
      ref_fasta_index = ref_fasta_index,
      ref_dict = ref_dict,
      input_cram = input_cram,
      input_cram_crai = input_cram_crai,
      region_bed = region_bed,
      sample_name = sample_name,
      docker_image = meltv2_docker,
      preemptible_tries = preemptible_tries
  }

  #call MELT Single 
  call MELTSingleTask{	
    input:
      ref_fasta = ref_fasta,
      ref_fasta_index = ref_fasta_index,
      input_bam = CramToBamTask.outputBam,
      input_bam_bai = CramToBamTask.outputBamBai,
      prior_files = prior_files,
      sample_name = sample_name,
      docker_image = meltv2_docker,
      preemptible_tries = preemptible_tries
  }

  #call MELT Deletion
  call MELTDelTask {	
    input:
      ref_fasta = ref_fasta,
      ref_fasta_index = ref_fasta_index,
      input_bam = CramToBamTask.outputBam,
      input_bam_bai = CramToBamTask.outputBamBai,
      sample_name = sample_name,
      docker_image = meltv2_docker,
      preemptible_tries = preemptible_tries
  }

  output {
    File outputALU = MELTSingleTask.outputALU
    File outputHERVK = MELTSingleTask.outputHERVK
    File outputLINE1 = MELTSingleTask.outputLINE1 
    File outputSVA = MELTSingleTask.outputSVA
    File outputDEL = MELTDelTask.outputDEL
  }
}

#Task Definitions
task CramToBamTask {
    # Command parameters
    File ref_fasta
    File ref_fasta_index
    File ref_dict
    File input_cram
    File input_cram_crai
    File region_bed
    String sample_name

    # Runtime parameters
    Int addtional_disk_size
    Int machine_mem_size
    String docker_image
    Int preemptible_tries

    Float output_bam_size = size(input_cram, "GB") / 0.60
    Float ref_size = size(ref_fasta, "GB") + size(ref_fasta_index, "GB") + size(ref_dict, "GB")
    Int disk_size = ceil(size(input_cram, "GB") + output_bam_size + ref_size) + addtional_disk_size

  #Calls samtools view to do the conversion
  command {
    set -e
    set -o pipefail
    
    samtools view -h -T ${ref_fasta} ${input_cram} -L ${region_bed} -O BAM -o ${sample_name}.bam
    samtools index -b ${sample_name}.bam
  }

  #Run time attributes:
  runtime {
    docker: docker_image
    memory: machine_mem_size + " GB"
    disks: "local-disk " + disk_size + " HDD"
    preemptible: preemptible_tries
  }

  #Outputs a BAM and BAI with the same sample name
  output {
    File outputBam = "${sample_name}.bam"
    File outputBamBai = "${sample_name}.bam.bai"
  }
}

task MELTSingleTask {
    File ref_fasta
    File ref_fasta_index
    File input_bam
    File input_bam_bai
    File prior_files
    String docker_image
    String sample_name
    Int addtional_disk_size
    Int machine_mem_size
    Int preemptible_tries

    Int disk_size = ceil(size(input_bam, "GB")) + addtional_disk_size
    Int command_mem_size = machine_mem_size - 1

  command {
        mkdir results
        tar -xzvf ${prior_files}
        echo -e "/data/melt/me_refs/Hg38/ALU_MELT.zip\tALU.1KGP.and.NIH.sites.hg38.vcf" > mei_list.txt
        echo -e "/data/melt/me_refs/Hg38/LINE1_MELT.zip\tLINE1.1KGP.and.NIH.sites.hg38.vcf" >> mei_list.txt
        echo -e "/data/melt/me_refs/Hg38/SVA_MELT.zip\tSVA.1KGP.and.NIH.sites.hg38.vcf" >> mei_list.txt
        echo "/data/melt/me_refs/Hg38/HERVK_MELT.zip" >> mei_list.txt
	java -Xmx${command_mem_size}G -Xms${command_mem_size}G -jar /data/melt/MELT.jar Single \
	     -t mei_list.txt \
             -n /data/melt/add_bed_files/Hg38/Hg38.genes.bed \
             -h ${ref_fasta} \
             -c 32 \
             -r 150 \
             -bowtie /usr/local/bin/bowtie2 \
             -samtools /usr/local/bin/samtools \
             -bamfile ${input_bam} \
             -w results/
        mv results/ALU.final_comp.vcf ${sample_name}.ALU.final_comp.vcf
        gzip ${sample_name}.ALU.final_comp.vcf
        mv results/HERVK.final_comp.vcf ${sample_name}.HERVK.final_comp.vcf
        gzip ${sample_name}.HERVK.final_comp.vcf
        mv results/LINE1.final_comp.vcf ${sample_name}.LINE1.final_comp.vcf
        gzip ${sample_name}.LINE1.final_comp.vcf
        mv results/SVA.final_comp.vcf ${sample_name}.SVA.final_comp.vcf
        gzip ${sample_name}.SVA.final_comp.vcf
  }

  runtime {
    docker: docker_image
    memory: machine_mem_size + " GB"
    disks: "local-disk " + disk_size + " HDD"
    preemptible: preemptible_tries
  }

  output {
    File outputALU = "${sample_name}.ALU.final_comp.vcf.gz"
    File outputHERVK = "${sample_name}.HERVK.final_comp.vcf.gz"
    File outputLINE1 = "${sample_name}.LINE1.final_comp.vcf.gz"
    File outputSVA = "${sample_name}.SVA.final_comp.vcf.gz"
  }
}

task MELTDelTask { 
    File ref_fasta
    File ref_fasta_index
    File input_bam
    File input_bam_bai
    Int addtional_disk_size
    Int machine_mem_size
    String docker_image
    String sample_name
    Int preemptible_tries

    Int disk_size = ceil(size(input_bam, "GB")) + addtional_disk_size
    Int command_mem_size = machine_mem_size - 1

  command {
        mkdir results
        java -Xmx${command_mem_size}G -Xms${command_mem_size}G -jar /data/melt/MELT.jar Deletion-Genotype \
 	     -bed /data/melt/all.te.deletion.MELT-DEL.hg38.bed \
             -h ${ref_fasta} \
             -samtools /usr/local/bin/samtools \
             -bamfile ${input_bam} \
             -w results/
        mv results/*.del.tsv ${sample_name}.DEL.tsv
        gzip ${sample_name}.DEL.tsv
  }

  runtime {
    docker: docker_image
    memory: machine_mem_size + " GB"
    disks: "local-disk " + disk_size + " HDD"
    preemptible: preemptible_tries
  }

  output {
    File outputDEL = "${sample_name}.DEL.tsv.gz"
  }
}
