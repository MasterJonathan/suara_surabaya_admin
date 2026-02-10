import 'package:flutter/material.dart';



enum DashboardPage {
  
  overview,
  profile,
  
  videoCall,
  callHistory,
  callSimulator,

  temaSiaran,
  bannerTop,
  popUp,
  infoSS,
  infoSSComment,

  kawanssPost,
  kawanssComment,
  postinganTerlapor,

  berita,

  changePassword,
  settings,
  usersAccountManagement,
  adminManagement,

  socialnetworkanalysis,
  reportCall,
  reportUserRegistration,
  reportInfoSSPost,
  reportKawanSSPost,

  chatManagement,
  kategoriss,

  


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