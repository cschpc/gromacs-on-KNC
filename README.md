### Description

Scripts to launch GROMACS runs on KNC (Taito-mic). See docs/ for documentation
and best practices.


### Usage

Copy scripts to your work directory and modify mic-job.sh (if needed).

```
ssh taito
git clone https://github.com/mlouhivu/gmx-knc-launcher

cd $WRKDIR/some-directory
cp ~/gmx-knc-launcher/* .

(edit mic-job.sh)

sbatch mic-job.sh
```

