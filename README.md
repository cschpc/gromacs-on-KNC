### Description

Scripts to launch GROMACS runs on Taito-mic.

### Usage

Copy scripts to your work directory and modify mic-job.sh as needed.

```
ssh taito
git clone https://github.com/mlouhivu/gmx-mic-launcher

cd $WRKDIR/some-directory
cp ~/gmx-mic-launcher/* .

(edit mic-job.sh)

sbatch mic-job.sh
```

