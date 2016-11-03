### Description

Scripts to launch GROMACS runs on KNC (Taito-mic). See
[docs/taito.md](docs/taito.md) for documentation and best practices on
Taito-mic.


### Usage

Copy scripts to your work directory and modify mic-job.sh (if needed).

```
ssh taito
git clone https://github.com/cschpc/gromacs-on-knc

cd $WRKDIR/some-directory
cp ~/gromacs-on-knc/* .

(edit mic-job.sh)

sbatch mic-job.sh
```

