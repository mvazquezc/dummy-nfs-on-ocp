FROM registry.access.redhat.com/ubi8:latest
ENV GOPATH=/go
RUN mkdir -p /go
RUN dnf install golang git -y && dnf clean all
RUN go get github.com/willscott/go-nfs
WORKDIR /go/src/github.com/willscott/go-nfs/example/osnfs
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o /usr/bin/nfs-server .
RUN mkdir -p /nfs-share
# You can get rid of next two dummy lines
RUN echo "This is a testfile owned by user 5000" > /nfs-share/testfile.txt
RUN touch /nfs-share/dummy{1..10} 
# End of dummy lines
# 1st option: with setgid
#RUN chown -R 5000:5000 /nfs-share && chmod 0770 /nfs-share && chmod 0660 /nfs-share/*
# 2nd option: without setgid
RUN chown -R 5000:5000 /nfs-share && chmod 0770 /nfs-share && chmod 0660 /nfs-share/*
USER 5000
EXPOSE 2049
CMD ["/usr/bin/nfs-server", "/nfs-share", "2049"]
