SOURCE_DIR=/home/artemis/perl510/lib/site_perl/5.10.0/Artemis/
DEST_DIR=/data/bancroft/artemis/live/nfsroot/installation_base/opt/artemis/lib/perl5/site_perl/5.10.0/Artemis/
DEST_DIR_DEVEL=/data/bancroft/artemis/development/nfsroot/installation_base/opt/artemis/lib/perl5/site_perl/5.10.0/Artemis/


live:
	./scripts/dist_upload_wotan.sh
	sudo rsync -ruv  ${SOURCE_DIR}/Installer.pm ${DEST_DIR} 
	sudo rsync -ruv  ${SOURCE_DIR}/Installer/ ${DEST_DIR}/Installer/
devel:
	./scripts/dist_upload_wotan.sh
	sudo rsync -ruv  ${SOURCE_DIR}/Installer.pm ${DEST_DIR_DEVEL} 
	sudo rsync -ruv  ${SOURCE_DIR}/Installer/ ${DEST_DIR_DEVEL}/Installer/ 
