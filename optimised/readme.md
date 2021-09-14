Run `asar --fix-checksum=off "main.asm" SM.smc`, it will print out some flags to copy paste for the python script, e.g.
    ` --p_spcEngine=43E --p_sharedTrackers=34AC --p_noteLengthTable=3882 --p_instrumentTable=389A --p_sampleTable=3A00 --p_sampleData=3B00 --p_p_trackers=47`
    
Run `python repoint.py SM.smc SM_out.smc --p_spcEngine=43E etc.`
