# See here for image contents: https://github.com/microsoft/vscode-dev-containers/tree/v0.155.1/containers/dotnet/.devcontainer/base.Dockerfile

FROM mcr.microsoft.com/quantum/iqsharp-base:latest

# Change user
USER root

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

# Install Python SDK for optimization (QIO)
RUN /opt/conda/bin/pip install notebook azure-quantum jupytext

# Install SDK for Python host programs that call Q# operations.
# https://docs.microsoft.com/en-us/azure/quantum/install-python-qdk?tabs=tabid-conda
RUN conda create -n qsharp -c quantum-engineering qsharp notebook