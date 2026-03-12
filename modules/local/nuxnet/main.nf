process NUXNET {
    tag "$meta.id"
    label 'process_gpu'

    container "ghcr.io/luiskuhn/nuxnet-inference-test:test"

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
    def smoke_args = task.ext.smoke_args ?: '--input-shape 8,16,16 --arch unet3d --classes 3 --in-channels 1 --no-cuda'
    prefix = task.ext.prefix ?: "${meta.id}"

    """
    mkdir -p ${prefix}
    img_dir=\$(readlink -f ${img_directory})

    nuxnet-pred smoke-test \\
        --output .smoke/${prefix} \\
        $smoke_args

    nuxnet-pred predict \\
        --input \$img_dir \\
        --output ${prefix}/${prefix} \\
        --model ${model_file} \\
        $args

    NUXNET_VERSION=\$(nuxnet-pred --version 2>/dev/null | head -n 1 | tr -d '\\r' || true)
    if [[ -z "\$NUXNET_VERSION" ]]; then
        NUXNET_VERSION="unknown"
    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        nuxnet-inference: \$NUXNET_VERSION
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
        nuxnet-inference: test
    END_VERSIONS
    """
}
