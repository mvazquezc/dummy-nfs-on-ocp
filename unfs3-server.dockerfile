# quay.io/mavazque/nfs-server:latest
FROM fedora:32
RUN dnf install rpcbind https://ftp.tu-chemnitz.de/pub/linux/dag/redhat/el6/en/x86_64/rpmforge/RPMS/unfs3-0.9.22-2.el6.rf.x86_64.rpm -y && dnf clean all
RUN mkdir -p /nfs-share
RUN echo "/nfs-share 0.0.0.0/0(rw,insecure,no_root_squash)" > /etc/exports
ADD start.sh /usr/local/bin/
RUN useradd nfsowner -u 5000 -U -M -s /sbin/nologin 
# You can get rid of the following test line
RUN echo "This is a testfile owned by user 5000" > /nfs-share/testfile.txt
# End of test line
RUN chown -R nfsowner:nfsowner /nfs-share && chmod 2775 /nfs-share && chmod 0660 /nfs-share/*
USER 0
EXPOSE 2049
CMD ["start.sh"]
