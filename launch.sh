
BIGCAT_BRANCH=master
ID_SERVICE_BRANCH=master
GALA_BRANCH=quick-features
CONDA_ENV_NAME=bigcat-launch
MAXID=0
VOLUME=bigcat/data/sample_B_20160708_frags_46_50.hdf

### DOWNLOAD AND INSTALL

# clone id-service
if ! [ -d id-service ]; then
  git clone -b $ID_SERVICE_BRANCH https://github.com/saalfeldlab/id-service
else
  cd id-service
  git checkout $ID_SERVICE_BRANCH
  git pull origin $ID_SERVICE_BRANCH
  cd ..
fi
echo $MAXID > id-service/max_id.txt

# clone and install gala
if ! [ -d gala ]; then
  git clone --depth 50 -b $GALA_BRANCH https://github.com/jni/gala
else
  cd gala
  if ! [ `git rev-parse --verify $GALA_BRANCH` ]; then
    git fetch origin $GALA_BRANCH
    git checkout --track origin/$GALA_BRANCH
  else
    git checkout $GALA_BRANCH
    git pull origin $GALA_BRANCH
  fi
  cd ..
fi
cd gala
source activate $CONDA_ENV_NAME
if ! [ $? -eq 0 ]; then
  conda env create -n $CONDA_ENV_NAME
  source activate $CONDA_ENV_NAME
else
  conda env update -n $CONDA_ENV_NAME -f environment.yml
fi
pip install -e .
cd ..

# clone bigcat
if ! [ -d bigcat ]
then
  git clone -b $BIGCAT_BRANCH https://github.com/saalfeldlab/bigcat.git
else
  cd bigcat
  if ! [ `git rev-parse --verify $BIGCAT_BRANCH` ]; then
    git fetch origin $BIGCAT_BRANCH
    git checkout --track origin/$BIGCAT_BRANCH
  else
    git checkout $BIGCAT_BRANCH
    git pull origin $BIGCAT_BRANCH
  fi
  cd ..
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
unset PYTHONPATH
gala-serve $VOLUME -f config.json &
GALA_SERVICE_PID=$!

# run bigcat
java -Xmx3g -cp `< bigcat/cp.txt`:$HOME/.m2/repository/sc/fiji/bigcat/0.0.1-SNAPSHOT/bigcat-0.0.1-SNAPSHOT.jar \
  bdv.bigcat.BigCatRemoteClient \
  -i $VOLUME \
  -l /volumes/labels/fragments \
  -b config.json

kill $ID_SERVICE_PID
kill $GALA_SERVICE_PID

