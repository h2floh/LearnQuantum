# See here for image contents: https://github.com/microsoft/vscode-dev-containers/tree/v0.155.1/containers/dotnet/.devcontainer/base.Dockerfile

FROM mcr.microsoft.com/quantum/iqsharp-base:latest

# Add miniconda
RUN cd ~ && curl -Os https://repo.anaconda.com/miniconda/Miniconda3-4.5.11-Linux-x86_64.sh && \
    /bin/bash ~/Miniconda3-4.5.11-Linux-x86_64.sh -b -p /opt/conda && \
    rm ~/Miniconda3-4.5.11-Linux-x86_64.sh && \
    /opt/conda/bin/conda clean -tipsy && \
    ln -s /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh && \
    echo ". /opt/conda/etc/profile.d/conda.sh" >> ~/.bashrc && \
    echo "conda activate base" >> ~/.bashrc
ENV PATH /opt/conda/bin/:$PATH
RUN conda update conda

# Install Python Q# Environment
RUN conda update -n base -c quantum-engineering qsharp notebook

# [Option] Install Node.js
# ARG INSTALL_NODE="true"
# ARG NODE_VERSION="lts/*"
# RUN if [ "${INSTALL_NODE}" = "true" ]; then su vscode -c "umask 0002 && . /usr/local/share/nvm/nvm.sh && nvm install ${NODE_VERSION} 2>&1"; fi

# [Option] Install Azure CLI
# ARG INSTALL_AZURE_CLI="false"
# COPY library-scripts/azcli-debian.sh /tmp/library-scripts/
# RUN if [ "$INSTALL_AZURE_CLI" = "true" ]; then bash /tmp/library-scripts/azcli-debian.sh; fi \
#     && apt-get clean -y && rm -rf /var/lib/apt/lists/* /tmp/library-scripts

# [Optional] Uncomment this section to install additional OS packages.
# RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
#     && apt-get -y install --no-install-recommends <your-package-list-here>

# [Optional] Uncomment this line to install global node packages.
# RUN su vscode -c "source /usr/local/share/nvm/nvm.sh && npm install -g <your-package-here>" 2>&1