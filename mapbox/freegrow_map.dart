import 'package:auto_route/auto_route.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:freegrow_frontend/freegrow_frontend.dart';
import 'package:freegrow_frontend/model/enum.dart';
import 'package:get/get.dart';
import 'package:growmaps_official/router/app_router.gr.dart';
import 'package:growmaps_official/utils/shortcut_path.dart';
import 'package:growmaps_official/utils/timer.dart';
import 'package:growmaps_official/utils/value_state_updater.dart';
import 'package:growmaps_official/view/mapbox/freegrow_mapbox_controller.dart';
import 'package:freegrow_backend/freegrow_backend.dart';
import 'package:growmaps_official/view/new_home/map/map_page.dart';

import '../../utils/responsive.dart';

late FreeGrowMapController freeGrowMapController;

class FreegrowMap extends StatefulWidget {
  final BuildContext? childContext;

  const FreegrowMap({
    super.key,
    this.childContext,
  });

  @override
  State<FreegrowMap> createState() => _FreegrowMapState();
}

class _FreegrowMapState extends State<FreegrowMap> {
  double currentZoomLevel = 15.0;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    /// 이렇게 try catch를 추가함으로써 뒤로가기로 재시작 되는 경우에도, 작동됨.
    /// 재시작할때 ValueStateController
    try{
      if(freeGrowMapController.onMapboxLoaded == false){
      }
    }
    catch(e){
      freeGrowMapController = FreeGrowMapController(
        buildingDTO: ValueStateController.instance.buildingDTO,
        selectedFloor: ValueStateController.instance.selectedFloor,
        selectedPOI: ValueStateController.instance.selectedPOI,
        candidatePOI: ValueStateController.instance.candidatePOI,
        startPoint: ValueStateController.instance.startPoint,
        endPoint: ValueStateController.instance.endPoint,
        stopPlaceList: ValueStateController.instance.stopPlaceList,
        movingPathDTO: ValueStateController.instance.movingPathDTO,
      );
    }

  }

  @override
  Widget build(BuildContext context) {
    return FreeGrowMap(
      initialContent: freeGrowMapController.createInitialJavaScript(context),
      onWebViewCreated: (controller) {
        freeGrowMapController.createWebViewController(
            rawContext: context, webController: controller);
      },
      onStyleLoaded: () async {
        freeGrowMapController.setFloorPlanImages(ValueStateController.instance.selectedFloor).whenComplete(() async {
          await freeGrowMapController.updateMapData(whenInit: true);
        });
        freeGrowMapController.setMarkerLanguage(context);
        freeGrowMapController.onMapboxLoaded = true;
      },
      onPoiClick: (p0) async {
        if (ValueStateUpdater.instance.productType == ProductType.kiosk) {
          startTimer(context);
        }

        isConferenceView.value = false;
        bool change =
            ValueStateUpdater.instance.setSelectedPOI(selectedPOIUid: p0);
        print('onPoiClick : ${change} / ${p0}');
        if (change == true) {
          if ((AutoRouter.of(context).topRoute.name == RoutePathGuide.name)) {
            if (widget.childContext != null) {
              await ShortCutPath().push(
                  context: widget.childContext!,
                  routeName: RoutePOIDetails.name);
            }
            ValueStateUpdater.instance.setSelectedPOI(selectedPOIUid: null);
          } else {
            if (widget.childContext != null) {
              ShortCutPath().navigate(
                  context: widget.childContext!,
                  routeName: AutoTabsRouter.of(context).topRoute.name);
            } else {
              ShortCutPath().navigate(
                  context: context,
                  routeName: AutoRouter.of(context).topRoute.name);
            }
          }
        }
        DashboardInsert().update_bigQ_DashBoard('Click_poi_map',ValueStateController.instance.userDTO.value?.uid ?? FirebaseAuth.instance.currentUser?.uid ?? "userUid is empty", ValueStateController.instance.buildingDTO?.value?.buildingUid ?? "", poiUid: ValueStateController.instance.selectedPOI.value?.poiUid ?? "");
      },
      onMapClick: (p0) async {
        bool change =
            ValueStateUpdater.instance.setSelectedPOI(selectedPOIUid: null);
        if (change == true) {
          ShortCutPath().navigate(
              context: context,
              routeName: AutoRouter.of(context).topRoute.name);
        }
      },
      onMapZoom: (level) {
        // print("zoomLevel :: $level");
        currentZoomLevel = level;
      },
      onMove: (_) {
        if (ValueStateUpdater.instance.productType == ProductType.kiosk) {
          startTimer(context);
        }
      },
      onMapBounds: (data) {
        // print('남서 -> ${seLatLng}');
        // print('동북 -> ${neLatLng}');
      },
      onUpDownMarkerClick: (nodeUid) {
        if (ValueStateUpdater.instance.productType == ProductType.kiosk) {
          startTimer(context);
        }
        String? floorUid =
            freeGrowMapController?.moveToFloorUpDownMarkerClick(nodeUid);
        if (floorUid != null) {
          ValueStateController.instance.selectedFloor.value =
              ValueStateController.instance
                  .getFloorPlanList(floorUid: floorUid)
                  ?.first;

          // fixme 하드코딩 : 승/하차 클릭 시 해당 위치로 이동 추가 240422 - 성엽
          if(nodeUid.split(":")[0] == "out_ST_1"){
            // be4UpANZAL25rRNPCMZtDedb 1층 > LngLat(126.74376615204727, 37.667711496176636)
            // rXsyFay4iLjXyqNzY1iW8K14 2층 > LngLat(126.742404809508, 37.66523018537771)
            if(floorUid == "be4UpANZAL25rRNPCMZtDedb"){
              freeGrowMapController.cameraMove(moveType: "jumpTo", latlng: LatLngDTO(lat: 37.667711496176636, lng: 126.74376615204727));
            } else if (floorUid == "rXsyFay4iLjXyqNzY1iW8K14"){
              freeGrowMapController.cameraMove(moveType: "jumpTo", latlng: LatLngDTO(lat: 37.66523018537771, lng: 126.742404809508));
            }
          }
        }
        ShortCutPath().navigate(context: context, routeName: RouteMap.name);
      },
    );
  }

  void startTimer(BuildContext? context) {
    if (context != null) {
      TimerManager().startTimer(context);
    }
  }
}
