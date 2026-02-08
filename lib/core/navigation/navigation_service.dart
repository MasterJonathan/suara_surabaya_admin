import 'package:flutter/material.dart';



enum DashboardPage {
  
  overview,
  profile,
  
  videoCall,
  callSimulator,

  changePassword,
  settings,
  usersAccountManagement,
  adminManagement,

  temaSiaran,
  bannerTop,
  popUp,
  infoSS,
  infoSSComment,

  berita,
  kawanssManagement,
  kawanssPost,
  kawanssComment,

  reportUserRegistration,
  reportInfoSSPost,
  reportKawanSSPost,

  chatManagement,
  
  socialnetworkanalysis,

  kategoriss,

  

  postinganTerlapor,
  reportManagement,
  report
}

class NavigationService extends ChangeNotifier {

  DashboardPage _currentPage = DashboardPage.overview;
  DashboardPage get currentPage => _currentPage;


  void navigateTo(DashboardPage page) {
    if (_currentPage != page) { 
      _currentPage = page;
      notifyListeners();
    }
  }


}