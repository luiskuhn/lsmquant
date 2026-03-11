process NUXNET {
    tag "$meta.id"
    label 'process_gpu'

    container "nf-core/nuxnet:0.1.0"

    input:
    tuple val(meta), path(img_directory), path(parameter_file)
    path(model_file)

    output:
    path "${prefix}/*"              , emit: cellcounts
    path "versions.yml"             , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"

    """
    mkdir -p ${prefix}
    img_dir=\$(readlink -f ${img_directory})

    nuxnet predict \\
        --input \$img_dir \\
        --output_dir ${prefix} \\
        --model ${model_file} \\
        --sample_id ${prefix} \\
        $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        nuxnet: 0.1.0
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"

    """
    mkdir -p ${prefix}
    touch ${prefix}/${prefix}.csv
    touch ${prefix}/${prefix}_counts.csv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        nuxnet: 0.1.0
    END_VERSIONS
    """
}
