DECLARE
    CURSOR sobj_w_c IS
        SELECT swc.SOBJECT_ID_CHILD
        FROM WMS.Sobj_Weight_Content swc
        JOIN WMS.SOBJECT so ON so.SOBJECT_ID = swc.SOBJECT_ID_CHILD
        WHERE so.SOBJ_WEIGHT_TYPE_ID = 20; -- плохой способ проверять - при изменении на товаре, на коробах он не меняется
    
    v_sobj_w_c                 NUMBER;
    v_row_count                NUMBER;
    v_row_count_coverage       NUMBER;
    v_weight_fas               NUMBER;
    v_sobj_w_child             NUMBER;
    v_sobj_barcode             VARCHAR(2000);
BEGIN
    FOR sobj IN sobj_w_c
    LOOP
        v_sobj_w_c := sobj.SOBJECT_ID_CHILD;
        v_sobj_barcode := sobj.BARCODE_VALUE;
        v_weight_fas := NULL;
        
        BEGIN
            SELECT COUNT(*) 
            INTO v_row_count
            FROM WMS.SOBJ_LNK sl
            JOIN wms.sobject so ON so.SOBJECT_ID = sl.SOBJECT_ID_CHILD
            WHERE sl.SOBJECT_ID_PARENT = v_sobj_w_c -- зачем, если можно было сразу sobj.SOBJECT_ID_CHILD (для работы в блоках if else)
              AND sl.SOBJ_LNK_TYPE_ID = 1;

            IF v_row_count < 1 THEN -- если кол-во строк меньше одного, то это это штука
                BEGIN
                    SELECT sc.WEIGHT 
                    INTO v_weight_fas
                    FROM sobj_coverage s
                    JOIN sobj_coverage_content sc ON s.SOBJ_COVERAGE_ID = sc.SOBJ_COVERAGE_ID
                    WHERE sc.SOBJECT_ID = v_sobj_w_c
                      AND s.SOBJ_TYPE_ID = 1
                      AND s.SOBJ_UNIT_ID = 1 ---Уууу... вот это совсем грустно с мастер данными из КА))) Посмотри на колбасы с фикс весом...
                    FETCH FIRST 1 ROWS ONLY;
                    
                    IF v_weight_fas IS NOT NULL THEN
                        UPDATE WMS.Sobj_Weight_Content swc
                        SET swc.WEIGHT = v_weight_fas
                        WHERE swc.SOBJECT_ID_CHILD = v_sobj_w_c;
                    END IF;
                EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                        NULL;
                END;
            ELSE -- строк больше 1 и более => короб
                BEGIN
                    SELECT so.SOBJECT_ID -- вот тут гарантированно будет больше 1 записи, так что будет ошибка
                    INTO v_sobj_w_child
                    FROM WMS.SOBJ_LNK sl
                    JOIN wms.sobject so ON so.SOBJECT_ID = sl.SOBJECT_ID_CHILD
                    WHERE sl.SOBJECT_ID_PARENT = v_sobj_w_c
                    AND sl.SOBJ_LNK_TYPE_ID = 1;

                    SELECT COUNT(*)
                    INTO v_row_count_coverage
                    FROM sobj_coverage s
                    JOIN sobj_coverage_content sc ON s.SOBJ_COVERAGE_ID = sc.SOBJ_COVERAGE_ID
                    WHERE sc.SOBJECT_ID = v_sobj_w_child
                    AND s.SOBJ_TYPE_ID = 2;

                    IF v_row_count_coverage < 2 THEN --одна фасовка короба
                        SELECT sc.WEIGHT
                        INTO v_weight_fas
                        FROM sobj_coverage s
                        JOIN sobj_coverage_content sc ON s.SOBJ_COVERAGE_ID = sc.SOBJ_COVERAGE_ID
                        WHERE sc.SOBJECT_ID = v_sobj_w_child
                        AND s.SOBJ_TYPE_ID = 2;

                        UPDATE WMS.Sobj_Weight_Content swc
                        SET swc.WEIGHT = v_weight_fas
                        WHERE swc.SOBJECT_ID_CHILD = v_sobj_w_c;
                    ELSE
                        SELECT sc.WEIGHT
                        INTO v_weight_fas
                        FROM sobj_coverage s
                        JOIN sobj_coverage_content sc ON s.SOBJ_COVERAGE_ID = sc.SOBJ_COVERAGE_ID
                        JOIN WMS.SOBJ_COVERAGE_CONTENT_CODE sccc ON sccc.SOBJ_COVERAGE_ID = s.SOBJ_COVERAGE_ID
                        WHERE sc.SOBJECT_ID = v_sobj_w_child
                        AND s.SOBJ_TYPE_ID = 2
                        AND sccc.EAN_CODE = v_sobj_barcode; -- не совсем верно- у тебя в кодах же ГС1 есть) А уж про весовые ШК (которые с 2) я молчу

                        UPDATE WMS.Sobj_Weight_Content swc
                        SET swc.WEIGHT = v_weight_fas
                        WHERE swc.SOBJECT_ID_CHILD = v_sobj_w_c;
                    END IF;
                EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                        NULL; 
                END;
            END IF;
        EXCEPTION
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('Ошибка при обработке объекта ' || v_sobj_w_c);
        END;
    END LOOP;
END;
