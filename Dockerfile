FROM amazon/aws-cli

RUN yum update -y && \
    yum install -y jq shadow-utils && \
    yum clean all && rm -rf /var/cache/yum && \
    useradd -m bp-user

COPY build.sh /home/bp-user/
ADD BP-BASE-SHELL-STEPS /opt/buildpiper/shell-functions/



RUN chmod +x /home/bp-user/build.sh \
 && chmod -R a+rX /opt/buildpiper

USER bp-user
WORKDIR /home/bp-user

ENV SLEEP_DURATION 5s
ENV ACTIVITY_SUB_TASK_CODE BP_LAMBDA_STEP

ENTRYPOINT ["./build.sh"]
