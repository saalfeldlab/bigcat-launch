
BIGCAT_BRANCH=remote-client
ID_SERVICE_BRANCH=master
GALA_BRANCH=easy-launch
CONDA_ENV_NAME=bigcat-launch
MAXID=0
VOLUME=bigcat/data/sample_B_20160708_frags_46_50.hdf

### DOWNLOAD AND INSTALL

# clone id-service
git clone -b $ID_SERVICE_BRANCH https://github.com/saalfeldlab/id-service
echo $MAXID > id-service/max_id.txt

# clone and install gala
git clone -b $GALA_BRANCH https://github.com/jni/gala
cd gala
conda env create -n $CONDA_ENV_NAME
source activate $CONDA_ENV_NAME
pip install -e .
cd ..

# clone bigcat
if ! [ -d bigcat ]
then
  git clone -b $BIGCAT_BRANCH https://github.com/saalfeldlab/bigcat.git
fi

# build
cd bigcat
mvn install
mvn dependency:build-classpath -Dmdep.outputFile=cp.txt
cd ..

### RUN

# run id-service
python id-service/server.py &
ID_SERVICE_PID=$!

# run gala-serve
gala-serve $VOLUME -f config.json &
GALA_SERVICE_PID=$!

# run bigcat
java -Xmx3g -cp `< bigcat/cp.txt`:$HOME/.m2/repository/sc/fiji/bigcat/0.0.1-SNAPSHOT/bigcat-0.0.1-SNAPSHOT.jar \
  bdv.bigcat.BigCatRemoteClient \
  -i $VOLUME
  -b config.json

kill $ID_SERVICE_PID
kill $GALA_SERVICE_PID

