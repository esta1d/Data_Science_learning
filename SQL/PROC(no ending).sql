CREATE PROCEDURE res_get_smvm (
    v_smvm_id IN NUMBER,
    v_smvm_ref_count OUT NUMBER,
    v_d_res_map_id OUT NUMBER,
    v_IS_CANCELED OUT VARCHAR,
    v_qty_fact OUT NUMBER,
    v_smvm_id_ref OUT NUMBER,
    v_sobject_id OUT NUMBER,
    v_D_DO_SOBJECT_COVER_MAP NUMBER,
    v_D_DO_SOBJECT_ID NUMBER
)
IS
BEGIN
    SELECT dm.D_RESERVATION_MAP_ID, dm.IS_CANCELED, dm.D_DO_SOBJECT_COVER_MAP
    INTO v_d_res_map_id, v_IS_CANCELED, v_D_DO_SOBJECT_COVER_MAP
    FROM WMS.D_RESERVATION_MAP dm
    WHERE dm.D_RESERVATION_MAP_ID IN (SELECT sm.D_RESERVATION_MAP_ID
                                        FROM wms.smvm sm
                                        WHERE sm.SMVM_ID IN (v_smvm_id) and sm.SMVM_STATUS_ID in (1,0));
    IF v_IS_CANCELED = 'Y' THEN
        DBMS_OUTPUT.PUT_LINE('D_RESERVATION_MAP_ID: ' || v_d_res_map_id || ' уже отменен ' || v_IS_CANCELED || 'Проверь вручную!!!');
    ELSE
        update WMS.D_RESERVATION_MAP dm
        set dm.IS_CANCELED = 'Y'
        where dm.D_RESERVATION_MAP_ID = v_d_res_map_id;
    END IF;

    -- зануление позиций
    SELECT dp.qty_fact
    INTO v_qty_fact
    FROM WMS.D_DO_CONTAINER_POS dp
    WHERE dp.D_DO_CONTAINER_ID =
        (SELECT m.D_DO_CONTAINER_ID
            FROM WMS.D_RESERVATION_MAP m
            WHERE m.D_RESERVATION_MAP_ID IN (SELECT sm.D_RESERVATION_MAP_ID
                                                FROM wms.smvm sm
                                            WHERE sm.SMVM_ID IN (v_smvm_id)));
    
    IF v_qty_fact > 0 THEN -- если хоть что-то подобрали, то проставляем 0 в факте
        UPDATE WMS.D_DO_CONTAINER_POS dp
        SET dp.QTY_FACT = 0
        WHERE dp.D_DO_CONTAINER_ID =
        (SELECT m.D_DO_CONTAINER_ID
            FROM WMS.D_RESERVATION_MAP m
            WHERE m.D_RESERVATION_MAP_ID IN (SELECT sm.D_RESERVATION_MAP_ID
                                                FROM wms.smvm sm
                                            WHERE sm.SMVM_ID IN (v_smvm_id)));
        -- и удаляем подобранное
        DELETE
        FROM WMS.D_DO_CONTAINER_POS_DETAIL dp
        WHERE dp.D_DO_CONTAINER_ID = (SELECT m.D_DO_CONTAINER_ID
                                    FROM WMS.D_RESERVATION_MAP m
                                    WHERE m.D_RESERVATION_MAP_ID IN (SELECT sm.D_RESERVATION_MAP_ID
                                                                    FROM wms.smvm sm
                                                                    WHERE sm.SMVM_ID IN (v_smvm_id)));
    END IF;


    SELECT sm.smvm_id_ref, sm.smvm_id_ref
    INTO v_smvm_ref_count, v_smvm_id_ref
    FROM wms.smvm sm
    WHERE sm.SMVM_ID IN (v_smvm_id) and sm.SMVM_STATUS_ID in (1,0);
    
    IF v_smvm_ref_count is NULL THEN -- проверяем есть ли ref, если нет, то работает только с основным перемещением
        declare -- удаляем перемещения 
            OUT_MESSAGE varchar2(2000);
            sm number;
            OUT_IS_ERROR number;
        begin
            for i in (select  m.* from wms.smvm m where m.SMVM_ID in (v_smvm_id) and m.SMVM_STATUS_ID  in (1,0) ) --
            loop
            sm := i.smvm_id;
            PKG_SMVM.DEL(sm, OUT_IS_ERROR , OUT_MESSAGE , 0);
            end loop;
        end;
    ELSE -- есть реф - удаляем его
        declare -- удаляем перемещения 
            OUT_MESSAGE varchar2(2000);
            sm number;
            OUT_IS_ERROR number;
        begin
            for i in (select  m.* from wms.smvm m where m.SMVM_ID in (v_smvm_id, v_smvm_id_ref) and m.SMVM_STATUS_ID  in (1,0) ) --
            loop
            sm := i.smvm_id;
            PKG_SMVM.DEL(sm, OUT_IS_ERROR , OUT_MESSAGE , 0);
            end loop;
        end;
    END IF;

    select d.SOBJECT_ID
    INTO v_sobject_id
    from WMS.D_DO_SOBJECT d 
    where d.D_DO_SOBJECT_ID = (select dc.D_DO_SOBJECT_ID 
                            from WMS.D_DO_SOBJECT_COVER_MAP dc 
                            where dc.D_DO_SOBJECT_COVER_MAP_ID = v_D_DO_SOBJECT_COVER_MAP);

    
    
END;
