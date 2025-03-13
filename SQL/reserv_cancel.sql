/* Formatted on 10/03/2025 23:16:57 (QP5 v5.388) */
SELECT *
  FROM D_DO_CONTAINER dc
 WHERE     dc.D_ORDER_ID IN (SELECT do.D_ORDER_ID
                               FROM WMS.D_ORDER do
                              WHERE do.D_ORDER_NUMBER IN ('АТ00-039903',
                                                          'АТ00-039976',
                                                          'АТ00-039870',
                                                          'АТ00-039815'))
       AND dc.D_DO_CONTAINER_STATUS_ID = 1;


SELECT ROWID, dp.*
  FROM WMS.D_DO_CONTAINER_POS dp
 WHERE dp.D_DO_CONTAINER_ID IN
           (SELECT dc.D_DO_CONTAINER_ID
             FROM D_DO_CONTAINER dc
            WHERE     dc.D_ORDER_ID IN
                          (SELECT do.D_ORDER_ID
                             FROM WMS.D_ORDER do
                            WHERE do.D_ORDER_NUMBER IN ('АТ00-039903',
                                                        'АТ00-039976',
                                                        'АТ00-039870',
                                                        'АТ00-039815'))
                  AND dc.D_DO_CONTAINER_STATUS_ID = 1);


SELECT *
  FROM WMS.D_DO_CONTAINER_POS_DETAIL dp
 WHERE dp.D_DO_CONTAINER_ID IN
           (SELECT dc.D_DO_CONTAINER_ID
             FROM D_DO_CONTAINER dc
            WHERE     dc.D_ORDER_ID IN
                          (SELECT do.D_ORDER_ID
                             FROM WMS.D_ORDER do
                            WHERE do.D_ORDER_NUMBER IN ('АТ00-039903',
                                                        'АТ00-039976',
                                                        'АТ00-039870',
                                                        'АТ00-039815'))
                  AND dc.D_DO_CONTAINER_STATUS_ID = 1);


SELECT ROWID, dp.*
  FROM WMS.D_RESERVATION_MAP dp
 WHERE dp.D_DO_CONTAINER_ID IN
           (SELECT dc.D_DO_CONTAINER_ID
             FROM D_DO_CONTAINER dc
            WHERE     dc.D_ORDER_ID IN
                          (SELECT do.D_ORDER_ID
                             FROM WMS.D_ORDER do
                            WHERE do.D_ORDER_NUMBER IN ('АТ00-039903',
                                                        'АТ00-039976',
                                                        'АТ00-039870',
                                                        'АТ00-039815'))
                  AND dc.D_DO_CONTAINER_STATUS_ID = 1);



DECLARE -- удаляем перемещения (убедится что удалили - это вернет товары в полки)
    OUT_MESSAGE    VARCHAR2 (2000);
    sm             NUMBER;
    OUT_IS_ERROR   NUMBER;
BEGIN
    FOR i
        IN (SELECT *
             FROM wms.smvm sm
            WHERE     sm.D_RESERVATION_MAP_ID IN
                          (SELECT dp.D_RESERVATION_MAP_ID
                            FROM WMS.D_RESERVATION_MAP dp
                           WHERE dp.D_DO_CONTAINER_ID IN
                                     (SELECT dc.D_DO_CONTAINER_ID
                                       FROM D_DO_CONTAINER dc
                                      WHERE     dc.D_ORDER_ID IN
                                                    (SELECT do.D_ORDER_ID
                                                      FROM WMS.D_ORDER do
                                                     WHERE do.D_ORDER_NUMBER IN
                                                               ('АТ00-039903',
                                                                'АТ00-039976',
                                                                'АТ00-039870',
                                                                'АТ00-039815'))
                                            AND dc.D_DO_CONTAINER_STATUS_ID =
                                                1))
                  AND sm.SMVM_STATUS_ID IN (0, 1))                          --
    LOOP
        sm := i.smvm_id;
        PKG_SMVM.DEL (sm,
                      OUT_IS_ERROR,
                      OUT_MESSAGE,
                      0);
    END LOOP;
END;
