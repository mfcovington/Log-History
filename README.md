# NAME

Log::History - Make self-documenting scripts that track their own execution history.

# SYNOPSIS

Place the import statement for Log::History wherever you want the log to start.

    use Log::History;
    #2014-02-02 12:43:08 (00:00:48) in /path/to/workingdir: /path/to/script.pl --opt 1 --param 2
    ...

To limit the number of log entries, specify how many to keep.
The oldest entries are discarded.

    use Log::History '3';
    #2014-05-27 ...
    #2007-12-18 ...
    #1987-12-18 ...

# DESCRIPTION

Log::History enables scripts to keep track of their own execution history.
Each log entry reports the date, start time, elapsed run time, working directory,
and a record of exactly how the script was called.

# ACKNOWLEDGEMENTS

I was inspired to write this after recently re-reading Neil Bowers' post:
[Identifying CPAN distributions you could help out with](http://blogs.perl.org/users/neilb/2012/12/modules-that-are-candidates-for-helping-out.html).
In it, I found Tushar Murudkar's no-longer-maintained module [Log::SelfHistory](https://metacpan.org/pod/Log::SelfHistory).
I was intrigued since I had been working on [Log::Reproducible](https://metacpan.org/pod/Log::Reproducible).
I wanted to go in a different direction, so decided to start from scratch instead of trying to take over [Log::SelfHistory](https://metacpan.org/pod/Log::SelfHistory).

# AUTHOR

Michael F. Covington <mfcovington@gmail.com>

# SEE ALSO

[Log::SelfHistory](https://metacpan.org/pod/Log::SelfHistory), [Log::Reproducible](https://metacpan.org/pod/Log::Reproducible)
