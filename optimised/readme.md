Run `asar --fix-checksum=off "main.asm" SM.sfc` (noting that the file extension must be SFC), it will print out some flags to copy paste for the python script, e.g.
    ` --p_spcEngine=43E --p_sharedTrackers=3481 --p_noteLengthTable=3855 --p_instrumentTable=386D --p_trackers=3957 --p_sampleTable=4A00 --p_sampleData=4B00`
    
Run `python repoint.py SM.sfc SM.smc --p_spcEngine=43E etc.`
