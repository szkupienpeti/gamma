/*
controller.operating.Secondary-entryActions -i- second.normal.Green --> second.normal.Yellow
*/
E<> (((__id_first_TrafficLightCtrl0__second == 5) && (__id_second_TrafficLightCtrl1__second == 2))) && P_System._StableLocation_
/*
controller.operating.SecondaryPrepares-entryActions -i- second.normal.Yellow --> second.normal.Red
*/
E<> (((__id_first_TrafficLightCtrl0__second == 1) && (__id_second_TrafficLightCtrl1__second == 1))) && P_System._StableLocation_
/*
controller.operating.Priority-entryActions -i- second.normal.Green --> second.normal.Yellow
*/
E<> (((__id_first_TrafficLightCtrl0__second == 2) && (__id_second_TrafficLightCtrl1__second == 2))) && P_System._StableLocation_
/*
controller.operating.Priority-entryActions -i- second.normal.Red --> second.normal.Green
*/
E<> (((__id_first_TrafficLightCtrl0__second == 2) && (__id_second_TrafficLightCtrl1__second == 4))) && P_System._StableLocation_
/*
controller.main_region.Operating --> controller.main_region.Operating -i- second.Main_region.Normal --> second.Main_region.Interrupted
*/
E<> (((__id_first_TrafficLightCtrl0__second == 8) && (__id_second_TrafficLightCtrl1__second == 8))) && P_System._StableLocation_
/*
controller.main_region.Operating --> controller.main_region.Operating -i- prior.Main_region.Interrupted --> prior.Main_region.Normal
*/
E<> (((__id_first_TrafficLightCtrl2__prior == 9) && (__id_second_TrafficLightCtrl3__prior == 9))) && P_System._StableLocation_
/*
controller.operating.PriorityPrepares-entryActions -i- prior.normal.Red --> prior.normal.Green
*/
E<> (((__id_first_TrafficLightCtrl2__prior == 4) && (__id_second_TrafficLightCtrl3__prior == 5))) && P_System._StableLocation_
/*
controller.operating.Secondary-entryActions -i- prior.normal.Red --> prior.normal.Green
*/
E<> (((__id_first_TrafficLightCtrl2__prior == 6) && (__id_second_TrafficLightCtrl3__prior == 5))) && P_System._StableLocation_
/*
controller.operating.SecondaryPrepares-entryActions -i- second.normal.Green --> second.normal.Yellow
*/
E<> (((__id_first_TrafficLightCtrl0__second == 1) && (__id_second_TrafficLightCtrl1__second == 2))) && P_System._StableLocation_
/*
controller.operating.Priority-entryActions -i- second.normal.Yellow --> second.normal.Red
*/
E<> (((__id_first_TrafficLightCtrl0__second == 2) && (__id_second_TrafficLightCtrl1__second == 1))) && P_System._StableLocation_
/*
controller.operating.Priority-entryActions -i- prior.normal.Yellow --> prior.normal.Red
*/
E<> (((__id_first_TrafficLightCtrl2__prior == 7) && (__id_second_TrafficLightCtrl3__prior == 3))) && P_System._StableLocation_
/*
controller.main_region.Operating --> controller.main_region.Operating -i- second.Main_region.Interrupted --> second.Main_region.Normal
*/
E<> (((__id_first_TrafficLightCtrl0__second == 8) && (__id_second_TrafficLightCtrl1__second == 7))) && P_System._StableLocation_
/*
controller.operating.Secondary-entryActions -i- prior.normal.Yellow --> prior.normal.Red
*/
E<> (((__id_first_TrafficLightCtrl2__prior == 6) && (__id_second_TrafficLightCtrl3__prior == 3))) && P_System._StableLocation_
/*
controller.operating.PriorityPrepares-entryActions -i- prior.normal.Yellow --> prior.normal.Red
*/
E<> (((__id_first_TrafficLightCtrl2__prior == 4) && (__id_second_TrafficLightCtrl3__prior == 3))) && P_System._StableLocation_
/*
controller.main_region.Operating --> controller.main_region.Operating -i- prior.Main_region.Normal --> prior.Main_region.Interrupted
*/
E<> (((__id_first_TrafficLightCtrl2__prior == 9) && (__id_second_TrafficLightCtrl3__prior == 10))) && P_System._StableLocation_
/*
controller.operating.Priority-entryActions -i- prior.normal.Red --> prior.normal.Green
*/
E<> (((__id_first_TrafficLightCtrl2__prior == 7) && (__id_second_TrafficLightCtrl3__prior == 5))) && P_System._StableLocation_
/*
controller.operating.Init-entryActions -i- prior.normal.Yellow --> prior.normal.Red
*/
E<> (((__id_first_TrafficLightCtrl2__prior == 3) && (__id_second_TrafficLightCtrl3__prior == 3))) && P_System._StableLocation_
/*
controller.operating.Priority-entryActions -i- prior.normal.Green --> prior.normal.Yellow
*/
E<> (((__id_first_TrafficLightCtrl2__prior == 7) && (__id_second_TrafficLightCtrl3__prior == 6))) && P_System._StableLocation_
/*
controller.operating.Secondary-entryActions -i- second.normal.Yellow --> second.normal.Red
*/
E<> (((__id_first_TrafficLightCtrl0__second == 5) && (__id_second_TrafficLightCtrl1__second == 1))) && P_System._StableLocation_
/*
controller.operating.Secondary-entryActions -i- prior.normal.Green --> prior.normal.Yellow
*/
E<> (((__id_first_TrafficLightCtrl2__prior == 6) && (__id_second_TrafficLightCtrl3__prior == 6))) && P_System._StableLocation_
/*
controller.operating.Init-entryActions -i- prior.normal.Red --> prior.normal.Green
*/
E<> (((__id_first_TrafficLightCtrl2__prior == 3) && (__id_second_TrafficLightCtrl3__prior == 5))) && P_System._StableLocation_
/*
controller.operating.PriorityPrepares-entryActions -i- prior.normal.Green --> prior.normal.Yellow
*/
E<> (((__id_first_TrafficLightCtrl2__prior == 4) && (__id_second_TrafficLightCtrl3__prior == 6))) && P_System._StableLocation_
/*
controller.operating.Init-entryActions -i- prior.normal.Green --> prior.normal.Yellow
*/
E<> (((__id_first_TrafficLightCtrl2__prior == 3) && (__id_second_TrafficLightCtrl3__prior == 6))) && P_System._StableLocation_
/*
controller.operating.SecondaryPrepares-entryActions -i- second.normal.Red --> second.normal.Green
*/
E<> (((__id_first_TrafficLightCtrl0__second == 1) && (__id_second_TrafficLightCtrl1__second == 4))) && P_System._StableLocation_
/*
controller.operating.Secondary-entryActions -i- second.normal.Red --> second.normal.Green
*/
E<> (((__id_first_TrafficLightCtrl0__second == 5) && (__id_second_TrafficLightCtrl1__second == 4))) && P_System._StableLocation_
