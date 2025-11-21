FROM scratch

ENV LANG=en_US.UTF-8

ADD archlinux.tar /

CMD ["/usr/bin/bash"]
