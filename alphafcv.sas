/* $Id:$ */
/* ----------------------------------------
 * AlphaFCV.sas (003)
 *
 *   Performs field-content analysis on
 *   all character fields in a SAS data
 *   object.  Works on data sets and views.
 *
 * ---------------------------------------- */

%macro AlphaFCV(DSN=0,LIB=,MEM=,TOP=28,
    NUMFMT=comma12.,PCTFMT=percent8.1,VVN=NORMAL);

    %put MHN-NOTE:  Now running AlphaFCV v3.7;

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

    data _null_;
        if 0 then set alpha nobs = nobs;
        call symputx( 'NOBS', nobs );
    run;

    %if &NOBS. = 0 %then %return;

    proc sort data = alpha;
        by name;
    run;

    data _null_;
        set alpha end = lastrec;
        length NS $ 5;
        NS = left( put( _n_, 5. ) );
        %if "&VVN." = "ANY" %then %do;
            call symputx( '_V' || trim( NS ), "'" || trim( name ) || "'n" );
            %end;
        %else %do;
            call symputx( '_V' || trim( NS ), trim( name ) );
            %end;
        if label ^= "" then call symputx( '_L' || trim( NS ), trim(name) || ' [' || trim( label ) || ']' );
        else call symputx( '_L' || trim( NS ), name );
        call symputx( '_F' || trim( NS ), format );
        if lastrec then call symputx( '_N', trim( NS ) );
    run;

    proc sql noprint;
        select count( * ) into :DENOM
        from &TNAM.
            ;

    %do i = 1 %to &_N;
        /*create view &&_V&i as*/
        create view _&i as
            select &&_V&i as value, count( * ) as rows
            from &TNAM.
            group by &&_V&i
            order by rows desc, value
            ;
    %end;

    quit;
    run;

    data _null_;
        call symputx( 'PRETTY', trim( left( put( &DENOM., &NUMFMT. ) ) ) );
        stop;
    run;

    %do i = 1 %to &_N;
        data peek;
            /*set &&_V&i.;*/
            set _&i.;
            pct = rows / &DENOM.;
            cumpct + pct;
            cumrows + rows;
            if _n_ > &TOP. then stop;
        run;

        proc report data = peek missing;
            columns value rows pct ( 'Cumulative' cumrows cumpct );
            define value / format=$60. 'Field Contents';
            define rows / format=&NUMFMT. 'Occurs';
            define pct / format=&PCTFMT. 'Percent';
            define cumrows / format=&NUMFMT. 'Rows';
            define cumpct / format=&PCTFMT. 'Percent';
            title2 "Field Under Analysis: &&_L&i.";
            title3 "Total rows in [&TNAM.]: &PRETTY..";
        run;

        %end;

    proc datasets nolist;
        delete peek alpha / mt=data;
        delete
            %do i = 1 %to &_N.;
               _&i.
            %end;
             / mt=view;
    quit;
    run;

%mend AlphaFCV;
/* EOF Jack N Shoemaker (JShoemaker@texturehealth.com) */
