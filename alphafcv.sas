/* $Id:$ */
/* ----------------------------------------
 * AlphaFCV
 *
 *   Performs field-content analysis on
 *   all character fields in a SAS data
 *   object.  Works on data sets and views.
 *
 * ---------------------------------------- */
%macro AlphaFCV(DSN=0,LIB=,MEM=,TOP=28,
    COLFMT=$CHAR80.,NUMFMT=comma12.,PCTFMT=percent8.1,VVN=NORMAL);

    %put MHN-NOTE:  Now running AlphaFCV v3.8;

    %local _N i DENOM TNAM;

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
        create table alpha as
            select name, label
            from dictionary.columns
            where upcase( type ) = 'CHAR' &
            upcase( libname ) = upcase( "&LIB." ) &
            upcase( memname ) = upcase( "&MEM." )
            ;
    quit;
    run;

    %if &SYSNOBS. = 0 %then %return;

    proc sort data = alpha;
        by name;
    run;

    data _null_;
        set alpha end = lastrec;
        %if "&VVN." = "ANY" %then %do;
            call symputx( catt( '_V', _n_ ), catt( "'", name, "'n" );
            %end;
        %else %do;
            call symputx( catt( '_V', _n_ ), trim( name ) );
            %end;
        if not( missing( label ) | ( trim( label ) = trim( name ) ) ) then
            call symputx( catt( '_L', _n_ ), catt( name, ' [', label, ']' ) );
        else
            call symputx( catt( '_L', _n_ ), trim( name ) );
        if lastrec then call symputx( '_N', left( put( _n_, 5. ) ) );
    run;

    proc sql noprint;
        select count( * ) into :DENOM
        from &TNAM.
            ;
    quit;

    %do i = 1 %to &_N;
        proc sql;
        create table peek as
            select &&_V&i as value, count( * ) as rows
            from &TNAM.
            group by &&_V&i
            ;
        quit;

        proc sort data = peek;
            by descending rows value;
        run;

        data peek;
            set peek;
            pct = rows / &DENOM.;
            cumpct + pct;
            cumrows + rows;
            if _n_ > &TOP. then stop;
        run;

        proc report data = peek missing;
            columns value rows pct ( 'Cumulative' cumrows cumpct );
            define value / format=&COLFMT. 'Field Contents';
            define rows / format=&NUMFMT. 'Occurs';
            define pct / format=&PCTFMT. 'Percent';
            define cumrows / format=&NUMFMT. 'Rows';
            define cumpct / format=&PCTFMT. 'Percent';
            title2 "Field Under Analysis: &&_L&i.";
            title3 "Total rows in [&TNAM.]: %sysfunc( int( &DENOM. ), &NUMFMT. )";
        run;

        %end;

    proc datasets nolist;
        delete peek alpha
            / mt = data;
    quit;
    run;
%mend AlphaFCV;
/* EOF Jack N Shoemaker (JShoemaker@texturehealth.com) */
