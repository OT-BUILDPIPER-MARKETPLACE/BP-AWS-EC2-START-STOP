FROM amazon/aws-cli

RUN yum update -y && \
    yum install -y jq shadow-utils && \
    yum clean all && rm -rf /var/cache/yum && \
    useradd -m bp-user

RUN groupadd -g 65522 buildpiper && \
    useradd -u 65522 -g buildpiper -d /home/buildpiper -m buildpiper && \
    chown -R buildpiper:buildpiper /home/buildpiper

COPY --chown=buildpiper:buildpiper build.sh /home/buildpiper/build.sh
COPY --chown=buildpiper:buildpiper BP-BASE-SHELL-STEPS /opt/buildpiper/shell-functions/

# FIXED: create /bp/workspace before chown
RUN mkdir -p /bp/workspace && \
    chmod +x /home/buildpiper/build.sh && \
    chown -R buildpiper:buildpiper /bp/workspace && \
    mkdir -p /home/buildpiper/reports && \
    chown -R buildpiper:buildpiper /home/buildpiper

USER buildpiper

WORKDIR /home/buildpiper

ENTRYPOINT ["./build.sh"]
