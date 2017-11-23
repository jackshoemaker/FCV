/* $Id:$ */
/* ----------------------------------------
 * NumerFCV.sas (003)
 *
 *   Performs field-content analysis on
 *   all numeric fields in a SAS data
 *   object.  Works on data sets and views.
 *
 * ---------------------------------------- */

%macro NumerFCV(DSN=0,LIB=,MEM=,NZ=N,
    NUMFMT=best12.,DATEFMT=yymmdd10.,DTFMT=datetime9.,VVN=NORMAL);

    %local _N i TNAM;

    %put MHN-NOTE:  Now running NumerFCV v3.7;

    %if "&DSN." = "0" %then %do;
        %let LIB = %upcase( &LIB );
        %let MEM = %upcase( &MEM );
        %let TNAM = &LIB..&MEM;
        %end;
    %else %do;
        %let TNAM = %upcase( &DSN. );
        %let LIB = %scan( &TNAM., 1, '.' );
        %let MEM = %scan( &TNAM., 2, '.' );
        %end;

    proc sql;
        create table numer as
            select name, label, format
            from dictionary.columns
            where upcase( type ) = 'NUM' &
            upcase( libname ) = upcase( "&LIB." ) &
            upcase( memname ) = upcase( "&MEM." )
            ;
    quit;
    run;

    data _null_;
        if 0 then set numer nobs = nobs;
        call symputx( 'NOBS', nobs );
    run;

    %if &NOBS. = 0 %then %return;

    proc sort data = numer;
        by name;
    run;

    data _null_;
        set numer end = lastrec;
        length NS $ 5;
        NS = left( put( _n_, 5. ) );
        %if "&VVN." = "ANY" %then %do;
            call symputx( '_V' || trim( NS ), "'" || trim( name ) || "'n" );
            %end;
        %else %do;
            call symputx( '_V' || trim( NS ), trim( name ) );
            %end;
        if label ^= "" then call symputx( '_L' || trim( NS ), label );
        else call symputx( '_L' || trim( NS ), name );
        call symputx( '_F' || trim( NS ), format );
        if lastrec then call symputx( '_N', trim( NS ) );
    run;

    %do i = 1 %to &_N;
        proc univariate data = &TNAM. noprint;
            %if %upcase( &NZ ) = Y %then %do;
                where &&_V&i > .;
                %end;
            var &&_V&i;
            output out = stats
                n = nobs sum = tot mean = avg
                min = min q1 = q1 median = median q3 = q3 max = max;
        run;

        data stats;
            length name $ 32 label $ 80 format $ 32;
            set stats;
            name = "&&_V&i";
            label = "&&_L&i";
            format = "&&_F&i";
        run;

        proc append base = report data = stats;
        run;
        %end;

    data report datevar dtvar;
        set report;
        if prxmatch( '/TIME/', format ) > 0 then output dtvar;
        else if prxmatch( '/DATE|YY|QQ|MON/', format ) > 0 then output datevar;
        else output report;
    run;

    proc report data = report missing;
        columns name
            ( '. Parametric Statistics .' nobs tot avg )
            ( '. Rank Statistics .' min q1 median q3 max );
        define name / order format=$32. 'Column Name';
        define nobs / display format=comma11. 'N Obs';
        define tot / display format=&NUMFMT. 'Total';
        define avg / display format=&NUMFMT. 'Average';
        define min / display format=&NUMFMT. 'Minimum';
        define q1 / display format=&NUMFMT. '25th Pct';
        define median / display format=&NUMFMT. 'Median';
        define q3 / display format=&NUMFMT. '75th Pct';
        define max / display format=&NUMFMT. 'Maximum';
        title2 "Numeric Field Content Analysis:  &TNAM.";
    run;

    proc report data = datevar missing;
        columns name
            ( '. Parametric .' nobs avg )
            ( '. Rank Statistics .' min q1 median q3 max );
        define name / order format=$32. 'Column Name';
        define nobs / display format=comma11. 'N Obs';
        define avg / display format=&DATEFMT. 'Average';
        define min / display format=&DATEFMT. 'Minimum';
        define q1 / display format=&DATEFMT. '25th Pct';
        define median / display format=&DATEFMT. 'Median';
        define q3 / display format=&DATEFMT. '75th Pct';
        define max / display format=&DATEFMT. 'Maximum';
        title2 "Date Field Content Analysis:  &TNAM.";
    run;

    proc report data = dtvar missing;
        columns name
            ( '. Parametric .' nobs avg )
            ( '. Rank Statistics .' min q1 median q3 max );
        define name / order format=$32. 'Column Name';
        define nobs / display format=comma11. 'N Obs';
        define avg / display format=&DTFMT. 'Average';
        define min / display format=&DTFMT. 'Minimum';
        define q1 / display format=&DTFMT. '25th Pct';
        define median / display format=&DTFMT. 'Median';
        define q3 / display format=&DTFMT. '75th Pct';
        define max / display format=&DTFMT. 'Maximum';
        title2 "Date-Time Field Content Analysis:  &TNAM.";
    run;

    proc datasets nolist;
        delete report datevar dtvar stats numer;
    quit;
    run;

%mend NumerFCV;
/* EOF Jack N Shoemaker (JShoemaker@texturehealth.com) */
