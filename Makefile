IMAGE_BASE:=ghcr.io/luzifer-docker/archlinux

default: seed
default: docker-image_minimal
default: docker-image-test_latest
default: docker-push_latest

jenkins: docker-image_minimal
jenkins: docker-image-test_latest
jenkins: docker-push_latest

jenkins: docker-image_base
jenkins: docker-image-test_base
jenkins: docker-push_base

jenkins: docker-image_base-devel
jenkins: docker-image-test_base-devel
jenkins: docker-push_base-devel

rootfs_minimal:
	docker run --rm -i -v "$(CURDIR):$(CURDIR)" -w "$(CURDIR)" \
		--privileged --tmpfs=/tmp:exec --tmpfs=/run/shm \
		$(IMAGE_BASE):latest \
		sh -c 'pacman -Sy --noconfirm devtools tar && bash mkroots.sh'

rootfs_%:
	docker run --rm -i -v "$(CURDIR):$(CURDIR)" -w "$(CURDIR)" \
		--privileged --tmpfs=/tmp:exec --tmpfs=/run/shm \
		$(IMAGE_BASE):latest \
		sh -c 'pacman -Sy --noconfirm devtools tar && bash mkroots.sh $*'

docker-image_minimal: rootfs_minimal
	docker build -t $(IMAGE_BASE):latest .

docker-image_%:
	$(MAKE) rootfs_$*
	docker build -t $(IMAGE_BASE):$* .

docker-image-test_%:
	# FIXME: /etc/mtab is hidden by docker so the stricter -Qkk fails
	docker run --rm $(IMAGE_BASE):$* sh -c "/usr/bin/pacman -Sy && /usr/bin/pacman -Qqk"
	docker run --rm $(IMAGE_BASE):$* sh -c "/usr/bin/pacman -Syu --noconfirm docker && docker -v"
	# Ensure that the image does not include a private key
	! docker run --rm $(IMAGE_BASE):$* pacman-key --lsign-key pierre@archlinux.de
	docker run --rm $(IMAGE_BASE):$* sh -c "/usr/bin/id -u http"
	docker run --rm $(IMAGE_BASE):$* sh -c "/usr/bin/pacman -Syu --noconfirm grep && locale | grep -q UTF-8"

docker-push_%:
	docker push $(IMAGE_BASE):$*

# Special build target to locally build the first minimal image
seed: test_archlinux
	bash mkroots.sh
	docker build -t $(IMAGE_BASE):latest .

test_archlinux:
	which pacstrap

.PHONY: rootfs docker-image docker-image-test ci-test docker-push
