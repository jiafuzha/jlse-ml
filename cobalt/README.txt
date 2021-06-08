1. copy all config files under "conf-to-your-submit-dir" to your working directory where you run submission script.

2. run "/path-to-submit-script/bin/submit-spark.sh -h" to see how to run your Spark job in different ways.

3. change to your working directory and run the submission script. For example, you can run KMeans example with below
   command assuming numpy is installed under user home dir and kmeans dataset is copied to DAOS folder
   "/jlse/kmeans/ukmeans.csv".

	$ /path-to-submit-script/bin/submit-spark.sh -t 60 -n 2 -q presque_debug /path-to-submit-script/example/kmeans_example.py daos:///jlse/kmeans/ukmeans.csv csv 10 

	Since the example KMeans job uses Spark KMeans lib depending on python lib “numpy”, you should install numpy
	directly or via Conda under your home directory. Here are simple steps to install MiniConda and “numpy”.

	$ wget https://repo.anaconda.com/miniconda/Miniconda3-4.5.4-Linux-x86_64.sh
	$ sh Miniconda3-4.5.4-Linux-x86_64.sh
	### re-login to load Miniconda3 and use default “base” env
	$ pip3 install numpy
	### verify if numpy is installed correctly
	$ pip3 list | grep numpy


4. check README.docx for script details.
