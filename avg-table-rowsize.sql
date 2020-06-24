

     set serverout ON size 1000000
     set ver off
     ACCEPT tbnm PROMPT 'Enter name of table to be computed: '
     ACCEPT tbown PROMPT 'Enter table owner: '
     DEF dot = "."

     spool &tbnm.lst

     DECLARE

       V_SIZE  NUMBER(8,2) := 0;
       V_TOT_SIZE NUMBER(8,2) := 0;
       V_COLUMN VARCHAR2(255);
       V_INIT_SIZE NUMBER;
       V_CURSOR_ID INTEGER;
       V_DYNAMIC_SQL VARCHAR2(500);
       V_DUMMY INTEGER;
       
       CURSOR SLC_TAB_COL_CURSOR IS
         SELECT column_name
         FROM all_tab_columns
         WHERE table_name=upper('&tbnm')
         AND   owner = upper('&tbown');

         SLC_TAB_COL_REC SLC_TAB_COL_CURSOR%ROWTYPE;

     BEGIN

        dbms_output.put_line(chr(10));
        FOR SLC_TAB_COL_REC IN SLC_TAB_COL_CURSOR LOOP

            V_COLUMN := SLC_TAB_COL_REC.COLUMN_NAME;
            
            -- open dynamic cursor for average column size
            V_CURSOR_ID := DBMS_SQL.OPEN_CURSOR;
            
            -- build query
            V_DYNAMIC_SQL := 'SELECT NVL(AVG(VSIZE(' || V_COLUMN || ')), 0) FROM &tbown&dot&tbnm';
            
            -- parse the query
            DBMS_SQL.PARSE(V_CURSOR_ID, V_DYNAMIC_SQL, DBMS_SQL.V7);
            
            -- define the output variable
            DBMS_SQL.DEFINE_COLUMN(V_CURSOR_ID, 1, V_SIZE);
            
            -- execute the statement
            V_DUMMY := DBMS_SQL.EXECUTE(V_CURSOR_ID);
            
            -- fetch the result row (if non-zero return code, bail out)
            IF DBMS_SQL.FETCH_ROWS(V_CURSOR_ID) = 0 THEN 
                EXIT;
            END IF;
            
            -- retrieve the output variable
            DBMS_SQL.COLUMN_VALUE(V_CURSOR_ID, 1, V_SIZE);
                       
            -- close the dynamic cursor 
            DBMS_SQL.CLOSE_CURSOR(V_CURSOR_ID);
            
            V_TOT_SIZE := V_TOT_SIZE + V_SIZE;
            
            dbms_output.put_line('Col. Name: '||V_COLUMN||'  '||' Avg. Size: '||V_SIZE);

       END LOOP;

       dbms_output.put_line(chr(10)||'Average Table Rowsize is : '||V_TOT_SIZE||' bytes');

     END;
/
