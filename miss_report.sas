/* $Id:$ */
/* Adapted from original work by Mike Zdeb, FSL */
proc format;
    value nm . = '0' other = '1';
    value $ch ' ' = '0' other = '1';
    value ty 1 = 'NUM' 2 = 'CHAR';
run;

%macro DoIt(METHOD=COUNT,VLIST=);
    %local C TOKEN;
    %let C = 1;
    %let TOKEN = %scan( &VLIST., &C., ' ' );
    %do %while( &TOKEN. ^= );
        %if "&METHOD." = "COUNT" %then %do;
            %if &C. > 1 %then ,;
            count( distinct &TOKEN. ) as _&TOKEN.
            %end;
        %else %if "&METHOD." = "ASSIGN" %then %do;
            ColumnName = "&TOKEN.";
            Levels = _&TOKEN.;
            if _&TOKEN. > 0 then CardinalityRatio = &DBMS_OBS. / _&TOKEN.;
            else call missing( CardinalityRatio );
            output;
            %end;
        %let C = %eval( &C. + 1 );
        %let TOKEN = %scan( &VLIST., &C., ' ' );
        %end;
%mend DoIt;

%macro miss_report(TABLE_NAME=,INLIB=,LABEL=NO);

    proc sql noprint;
        select count(*) into :DBMS_OBS from &INLIB..&TABLE_NAME.;
        %if &DBMS_OBS = 0 %then %return;
        select name into :V separated by ' ' from dictionary.columns
            where upcase( libname ) = %upcase( "&INLIB." ) & upcase( memname ) = upcase( "&TABLE_NAME." );
        create table CardinalityRatio as select %DoIt(VLIST=&V.) from &INLIB..&TABLE_NAME.;
    quit;

    ods listing close;
    ods output onewayfreqs = tables( keep = table f_: frequency percent );
    run;

    proc freq data = &INLIB..&TABLE_NAME.;
        tables _all_ / missing;
        format _numeric_ nm. _character_ $ch.;
    run;

    ods output close;
    ods listing;
    run;

    proc contents data = &INLIB..&TABLE_NAME. noprint
        out = labels( keep = name label type rename =( name = ColumnName ) index = ( ColumnName ) );
    run;

    data _null_;
        set labels;
        call symputx( 'LABEL_EXIST', 0 );
        if lengthn( trimn( label ) ) > 0 then do;
            call symputx( 'LABEL_EXIST', 1 );
            stop;
            end;
    run;

    data report( keep = ColumnName type label miss ok p_: );
        length
            ColumnName $ 32
            ;
        format
            miss ok comma10. p_: 5.1 type ty.
            ;
        do until( last.table );
            set tables;
            by table notsorted;
            array names(*) f_: ;
            select ( names( _n_ ) );
                when ('0') do; miss = frequency; p_miss = percent; end;
                when ('1') do; ok = frequency;   p_ok = percent; end;
                end;
            end;
        miss = coalesce( miss, 0 );
        ok = coalesce( ok, 0 );
        p_miss = coalesce( p_miss, 0 );
        p_ok = coalesce( p_ok, 0 );
        ColumnName = scan( table, -1 );
        set labels key = ColumnName / unique;
        label
            miss = 'N_MISSING'
            ok = 'N_PRESENT'
            p_miss = '%_MISSING'
            p_ok = '%_PRESENT'
            ColumnName = 'COLUMN NAME'
            type = 'TYPE'
            label = 'LABEL'
            ;
    run;

    data CardinalityRatio( keep = ColumnName Levels CardinalityRatio );
        length
            ColumnName $ 32
            Levels 8
            CardinalityRatio 8
            ;
        format
            Levels comma16.
            CardinalityRatio comma16.2
            ;
        set CardinalityRatio;
        %DoIt(METHOD=ASSIGN,VLIST=&V.);
    run;

    proc sort data = report;
        by ColumnName;
    run;
    proc sort data = CardinalityRatio;
        by ColumnName;
    run;

    data report;
        merge report CardinalityRatio;
        by ColumnName;
    run;

    title1 "Missing values report with cardinality ratios for [&INLIB..&TABLE_NAME.]";
    proc print data = report label noobs;
        %if %upcase( &LABEL. ) ^= NO & &LABEL_EXIST. ^= 0 %then %do;
            id ColumnName label type;
            var miss p_miss ok p_ok Levels CardinalityRatio;
            %end;
        %else %do;
            id ColumnName type;
            var miss p_miss ok p_ok Levels CardinalityRatio;
            %end;
    run;

    proc datasets nolist;
        delete report tables CardinalityRatio;
    quit;
    run;

%mend miss_report;
/* EOF Jack N Shoemaker (JShoemaker@mdwise.org) */
