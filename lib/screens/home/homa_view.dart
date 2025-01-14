import 'package:expandable_bottom_sheet/expandable_bottom_sheet.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:stacked/stacked.dart';
import 'package:zam/core/constant/app/app_constants.dart';
import 'package:zam/core/extension/context_extension.dart';
import 'package:zam/screens/auth/auth_view.dart';
import 'package:zam/screens/data_add/data_add_view.dart';
import 'package:zam/screens/home/home_view_model.dart';
import 'package:zam/screens/home/subviews/expandable/expandable_view.dart';
import 'package:zam/screens/map/map_style.dart';
import 'package:zam/screens/profile/profile_view.dart';
import 'package:zam/widgets/custom_text_form_field.dart';

import '../../widgets/custom_text.dart';
import '../my_collection/my_collection_view.dart';

class HomeView extends StatelessWidget {
  const HomeView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<HomeViewModel>.reactive(
        viewModelBuilder: () => HomeViewModel(),
        onModelReady: (viewModel) => viewModel.init(context),
        builder: (context, viewModel, child) {
          return Scaffold(
              extendBody: true,
              resizeToAvoidBottomInset: false,
              body: Stack(
                children: [
                  viewModel.initialised
                      ? ExpandableBottomSheet(
                          key: viewModel.key,
                          onIsContractedCallback: () {},
                          onIsExtendedCallback: () => print('extended'),
                          persistentContentHeight:
                              viewModel.selectPlace == null ? 0 : 170,
                          background: mapAndSearchWidget(viewModel),
                          persistentHeader: viewModel.selectPlace != null
                              ? Container(
                                  decoration: const BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(15),
                                          topRight: Radius.circular(15))),
                                  constraints:
                                      BoxConstraints.expand(height: 40),
                                  child: Center(
                                    child: Container(
                                      height: 8.0,
                                      width: 50.0,
                                      color: Color.fromARGB(
                                          (0.25 * 255).round(), 0, 0, 0),
                                    ),
                                  ),
                                )
                              : Container(),
                          expandableContent: viewModel.selectPlace != null
                              ? HomeBottomSheet(
                                  place: viewModel.selectPlace!,
                                  detailReport: viewModel.detailReport,
                            loading: viewModel.loading,
                            meter: viewModel.radius*1000,
                                )
                              : Container())
                      : const Center(
                          child: CircularProgressIndicator(),
                        ),
                  if (viewModel.popUpVisible)
                    Stack(
                      children: [
                        GestureDetector(
                          onTap: () {
                            viewModel.popUpVisible = false;
                          },
                          child: Container(
                              width: double.infinity,
                              height: double.infinity,
                              color: context.themeData.colorScheme.onPrimary
                                  .withOpacity(0.3)),
                        ),
                        Positioned(
                            right: 10,
                            top: 130,
                            child: otherButtonContainer(context, viewModel))
                      ],
                    )
                ],
              ));
        });
  }

  Container otherButtonContainer(
      BuildContext context, HomeViewModel viewModel) {
    return Container(
      color: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        // mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(onPressed: () {
            viewModel.popUpVisible = false;
          }, child: Icon(Icons.close)),
          Padding(
            padding: const EdgeInsets.only(top:8.0),
            child: FloatingActionButton(onPressed: () {
              viewModel.popUpVisible = false;
              context.navigateTo(DataAddView());
            }, child: Icon(Icons.add)),
          ),

          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: FloatingActionButton(
              onPressed: () {
                viewModel.popUpVisible = false;
                context.navigateTo(MyCollectionView());
              },
              child: Icon(Icons.library_books),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: FloatingActionButton(
              onPressed: () async{
                viewModel.popUpVisible = false;
                await FirebaseAuth.instance.signOut();
                context.navigateToRemoveUntil(AuthView());
              },
              child: Icon(Icons.logout),
            ),
          ),
        ],
      ),
    );
  }

  Stack mapAndSearchWidget(HomeViewModel viewModel) {
    Set<Circle> circles = Set.from([
      if (viewModel.selectPlace != null)
        Circle(
          circleId: CircleId('circle'),
          fillColor: Colors.blueAccent.withOpacity(0.2),
          strokeColor: Colors.blueAccent.withOpacity(0.4),
          center: LatLng(
              viewModel.selectPlace!.result!.geometry!.location!.lat!,
              viewModel.selectPlace!.result!.geometry!.location!.lng!),
          radius: viewModel.radius * 1000,
        )
    ]);
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: ApplicationConstants.kGooglePlex,
          markers: viewModel.markers,
          myLocationButtonEnabled: false,
          onMapCreated: (GoogleMapController controller) {
            viewModel.controller = controller;
            controller.setMapStyle(MapStyle().retro);
          },
          circles: circles,
        ),
        if (!viewModel.popUpVisible)
          Positioned(
            right: 10,
            top: 130,
            child: FloatingActionButton(
                child: Icon(Icons.more_vert),
                onPressed: () {
                  viewModel.popUpVisible = true;
                  // viewModel.context.navigateTo(DataAddView());
                }),
          ),
        if (viewModel.selectPlace != null) sliderCalculateWidget(viewModel),
        Positioned(
          top: 35,
          left: 0,
          right: 0,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: CustomTextFormField(
                    controller: viewModel.searchController,
                    fillColor: Colors.white,
                    hintText: 'Sokak veya Apartman arayın',
                    onChange: (val) {
                      viewModel.getPlaces();
                    },
                    onTap: () {},
                    isSuffixIcon: GestureDetector(
                        onTap: () {
                          viewModel.getPlaces();
                        },
                        child: Icon(Icons.search)),
                    insideHint: true),
              ),
              ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(8),
                  itemCount: viewModel.places.length,
                  itemBuilder: (BuildContext context, int index) {
                    return Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: GestureDetector(
                        onTap: () {
                          viewModel.onTap(index);
                        },
                        child: Container(
                          height: 50,
                          alignment: Alignment.centerLeft,
                          padding: EdgeInsets.only(left: 10),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius:
                                  BorderRadius.all(Radius.circular(8))),
                          child: Text('${viewModel.places[index].description}'),
                        ),
                      ),
                    );
                  })
            ],
          ),
        ),
      ],
    );
  }

  Positioned sliderCalculateWidget(HomeViewModel viewModel) {
    return Positioned(
      right: 0,
      left: 0,
      bottom: 220,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 20,
            width: 200,
            child: RotatedBox(
              quarterTurns: 0,
              child: Slider(
                max: 0.5,
                min: 0.1,
                value: viewModel.radius,
                activeColor: Colors.blueAccent,
                inactiveColor: Colors.grey,
                onChanged: (newValue) {
                  viewModel.radius = newValue;
                  double zoom = newValue > 0.3 ? 15 : 17;
                  CameraUpdate cameraUpdate = CameraUpdate.newLatLngZoom(
                      LatLng(
                          viewModel
                              .selectPlace!.result!.geometry!.location!.lat!,
                          viewModel
                              .selectPlace!.result!.geometry!.location!.lng!),
                      zoom);
                  viewModel.controller.animateCamera(cameraUpdate);
                },
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
                viewModel.pointCalculate();

            },
            child: Container(
              width: 100,
              height: 35,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(30)),
                  color: Colors.blueAccent),
              child: Center(
                  child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.calculate,
                    color: Colors.white,
                  ),
                  SizedBox(
                    width: 5,
                  ),
                  Text(
                    'Hesapla',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ],
              )),
            ),
          ),
        ],
      ),
    );
  }

}
