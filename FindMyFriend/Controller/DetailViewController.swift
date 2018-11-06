//
//  DetailViewController.swift
//  FindMyFriend
//
//  Created by Janhon on 2018/10/30.
//  Copyright © 2018 ImProve. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

//        locationmanager.startUpdatingLocation() //停止GPS更新.

class DetailViewController: UIViewController  {
    
    @IBOutlet weak var mainMapView: MKMapView!
    
    let communicator = Communicator.shared
    
    let locationmanager = CLLocationManager()
    var lastPoint : CLLocationCoordinate2D? = nil
    var newPoint : CLLocationCoordinate2D? = nil
    
    var locationDeltaScale : Double = 0.2
    var friends = [Friends]()
    var locationManager = LocationManager()
    var id : String = ""
    var lat : String = ""
    var lon : String = ""
    var lastUpdateDateTime : String = ""
    var saveLocation = true
    var timer: Timer?
    var saveLatitude = Double()
    var saveLongitude = Double()
    var localCoordinate = [Locations]()
    @IBOutlet weak var showMemoryField: UIButton!
    
    func configureView() {
        // Update the user interface for the detail item.
    
        guard let item = detailItem  else {
            return
        }
        // Show title .
        self.title = item.friendName
        
        // Show friend content on mapView.
        self.id = item.id
        self.lat = item.lat
        self.lon = item.lon
        self.lastUpdateDateTime = item.lastUpdateDateTime
  
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        configureView()
        mainMapView.delegate = self   //Important! 將MKMapViewDelegate的協定,綁在身上.
        self.timer = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(saveToSever), userInfo: nil, repeats: true)
        self.timer = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(saveToLocalDataBase), userInfo: nil, repeats: true)
       
        guard CLLocationManager.locationServicesEnabled() else {
            //show alert to user.
            return
        }
        
        // Execute moveAndZoomMap() after 3.0 seconds.  //DispatchQueue 是Grant Central DisPath 的應用. //.main 執行在mainQueue
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5 ){
            self.moveAndZoomMap()
        }
        
        // Ask permission.
        locationmanager.requestAlwaysAuthorization()
        locationmanager.requestWhenInUseAuthorization()
        
        //Prepare locationManager.
        locationmanager.delegate = self  //Important! 將CLLocationManagerDelegate的協定,綁在身上.
        locationmanager.desiredAccuracy = kCLLocationAccuracyBestForNavigation //設定精確度 = (GPS. Wifi 定位,cell定位 擇佳者)
        locationmanager.activityType = .otherNavigation  //位移類型設定 .fitness 用行走的, 也可以選擇其他交通工具.
        locationmanager.startUpdatingLocation() //startUpdatingLocation() 給位置.  startUpdatingHeading() 給羅盤(面向的方向)
        
    }
    
    var detailItem: Friends? {
        didSet {
            // Update the view.
            configureView()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Execute moveAndZoomMap() after 3.0 seconds.  //DispatchQueue 是Grant Central DisPath 的應用. //.main 執行在mainQueue
        self.moveAndZoomMap()
        
    }
    
    func moveAndZoomMap(){
        
        guard let location = locationmanager.location else{
            print("Location is not ready.")
            return
        }
        doRefreshJob()
        
        for friend in friends{
            
            if friend.friendName == MY_NAME {
                continue
            }
            
            guard let coordinate = coordinateHelper(latitude: lat, longitude: lon) else {
                print("(#Line), \(friend.friendName) coordinate is nil")
                continue
            }
        
            // define user & user's friend distance to show 的 screen scale
            let latTypeDouble = coordinate.latitude
            let longitudeTypeDoulbe = coordinate.longitude
            locationDeltaScale = location.coordinate.latitude - latTypeDouble
        
            switch locationDeltaScale {
            case 0...0.000009:
                locationDeltaScale = 0.000002
            case 0.000009...0.00009:
                locationDeltaScale = 0.00002
            case 0.00009...0.0001:
                locationDeltaScale = 0.0002
            case 0.001...0.01:
                locationDeltaScale = 0.002
            case 0.01...0.05:
                locationDeltaScale = 0.5
            case 0.05...0.09:
                locationDeltaScale = 0.9
            case 0.09...0.9:
                locationDeltaScale = 1.1
            case 1...9:
                locationDeltaScale = 9
            default:
                locationDeltaScale = 0.2
            }
            print("locationDeltaScale : \(locationDeltaScale)")
            // Move and zoom the map.
            let span = MKCoordinateSpan(latitudeDelta: locationDeltaScale, longitudeDelta: locationDeltaScale)   //Span 地圖縮放 ()
            let latBetweenUser = (location.coordinate.latitude + latTypeDouble) / 2
            let lonBetweenUser = (location.coordinate.longitude + longitudeTypeDoulbe) / 2
            let pointBetweenUser = CLLocationCoordinate2DMake(latBetweenUser, lonBetweenUser);
        
            print("pointBetweenUser: \(pointBetweenUser)")
        
            let region = MKCoordinateRegion(center: pointBetweenUser, span: span)  //把span的參數 設定給Region
            mainMapView.setRegion(region, animated: true)
        
            // Add annotation
            var storeCoordinate = location.coordinate
            storeCoordinate.latitude = latTypeDouble
            storeCoordinate.longitude = longitudeTypeDoulbe
        
            let annotation = StoreAnnotation()  //用自創的class繼承Protocol, 取代MKPointAnnotation()
            annotation.coordinate = storeCoordinate
            annotation.title = title
            annotation.subtitle = lastUpdateDateTime
    
            self.mainMapView.addAnnotation(annotation)
            }
    }
    
    func coordinateHelper(latitude: String , longitude: String) -> CLLocationCoordinate2D? {
        guard let latitude = Double(lat) , let longitude = Double(lon) else {
            return nil
        }
        return CLLocationCoordinate2DMake(latitude, longitude)
    }
    
    //MARK:- MapKit delegates
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay)
        if  showMemoryField.isSelected == false {
            renderer.strokeColor = UIColor.blue
        } else {
            renderer.strokeColor = UIColor.red
        }
        renderer.lineWidth = 10.0
        return renderer
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func allowSendLocation(_ sender: UISwitch) {
        if sender.isOn{
            saveLocation = true
        }else{
            saveLocation = false
        }
    }
    
    @IBAction func showMemoryButton(_ sender: UIButton) {
        getLocalCoordinate()
        print("Success to draw")
    }
}


//擴充,可以讓各協定(Protocols),做拆分的動作. (以便放在自創.swift中)
// MARK : - MKMapViewDelegate Methods.
extension DetailViewController  :  MKMapViewDelegate {
    
    //當地圖的region被改變時 regionDidChangeAnimated 就會被呼叫.
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let coordinate = mapView.region.center
        print("Map Center: \(coordinate.latitude), \(coordinate.longitude)")
    }
    
    //將圖示改為大頭針.
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation{ //用is檢查型別
            return nil
        }
        
        //用自創的Protocol 簽協定.
        //annotation as? StoreAnnotation(轉型)
        //Cast annotation as StoreAnnotation type.
        guard let annotation = annotation as? StoreAnnotation else{
            assertionFailure("Fail to cast as StoreAnnotation.") //assertionFailure, DEBUG用, 用來看不該出現的問題. 不影響使用者.
            return nil
        }
        let identifier = "store"
        //到dequeueReusableAnnotationView回收機制中, 找View.
        //identifier 的設計是for唯一的識別使用.
        var result = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) //as? MKPinAnnotationView(將大頭針換成圖示 step1) //轉型.
        if result == nil{
            //            result = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            result = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
        }else{
            result?.annotation = annotation
        }
        result?.canShowCallout = true
        //        result?.pinTintColor = .blue //(將大頭針換成圖示 step2)
        //        result?.animatesDrop = true
        
        let image = UIImage(named: "pointRed.png") //(將大頭針換成圖示 step3)
        result?.image = image   //(將大頭針換成圖示 step3)
        
        // Left-calloutaccessoryview.
        let imageView = UIImageView(image: image)
        result?.leftCalloutAccessoryView = imageView
        
        // Right-calloutaccessoryview.
        let button  = UIButton(type: .detailDisclosure) //detailDisclosure apple內建紐之一
        // 用程式碼建立touchUpInside的監聽.
        button.addTarget(self, action: #selector(accessoryBtnPressed(sender:)), for: .touchUpInside)  //這是IBAcion平常幫我們做的事情.
        result?.rightCalloutAccessoryView = button
        
        return result
    }
    
    @objc
    func accessoryBtnPressed(sender : Any){
        //.alert .actionSheet, 選項少訊息多時, 用.alert.  選項多訊息少時,用.actionSheet.
        let alertText = "即將前往\(title ?? "")的位置"
        let alert = UIAlertController(title: alertText , message: "導航前往這個地點? (若地點不正確,則會導航至台北市館前路45號)", preferredStyle: .alert)
        //        let ok = UIAlertAction(title: "ok", style: .default , handler: nil)
        
        //((action) in 的後面放要做的事情)
        let ok = UIAlertAction(title: "ok", style: .default){(action) in
            self.navigateToFriend()
        }
        let cancel = UIAlertAction(title: "Cancel", style: .destructive){(action) in
            //...
        }
        
        alert.addAction(ok)
        alert.addAction(cancel)
        present(alert, animated: true, completion: nil) // present由下往上跳全螢幕.
    }
    
    func navigateToFriend(){
        
        //地圖導航(指定緯經度)
        guard let location = locationmanager.location else{
            print("Location is not ready.")
            return
        }
        // define user & user's friend distance to show 的 screen scale
        let latTypeDouble = Double(lat)!
        let longitudeTypeDoulbe = Double(lon)!
        
        //prepare source MKMapItem  (A點到B點)  //24.686525  121.815312
            
        let sourceCoordinate = CLLocationCoordinate2DMake(location.coordinate.latitude , location.coordinate.longitude)
        let sourcePlacemark = MKPlacemark(coordinate: sourceCoordinate)
        let sourceMapItem = MKMapItem(placemark: sourcePlacemark)
        
        //prepare target MKMapItem. (指定地點)
        //使用mapKit
        let targeCoordinate = CLLocationCoordinate2DMake(latTypeDouble, longitudeTypeDoulbe)
        let targetPlacemark = MKPlacemark(coordinate: targeCoordinate)
        let targeMapItem = MKMapItem(placemark: targetPlacemark)
        // MKMapItem- apple 提供相關功能的地點物件
        let options = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
        //呼叫地圖這個app
         MKMapItem.openMaps(with: [sourceMapItem,targeMapItem], launchOptions: options)//(A點到B點)
        //targetMapItem.openInMaps(launchOptions: options) //(指定地點)
    }
}

extension DetailViewController : CLLocationManagerDelegate{
    //MARK : -CLLocationManagerDelegate Methods.
    // 每個Protocol 第一個參數,都會放自己本身.  locations: [CLLocation] 當位置改變時, apple的CPU 在閒暇時, 把點存進[CLLocation]中.(最後面的最新)
    //didUpdateLocations 只有在位置改變時, 才會存點.
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        guard let coordinate = locations.last?.coordinate else{
            assertionFailure("Invaild coordinate or location.")  //assertionFailure, DEBUG用, 用來看不該出現的問題. 不影響使用者.
            return
        }
        saveLatitude = coordinate.latitude
        saveLongitude = coordinate.longitude
        
        print ("Current Location :  \(coordinate.latitude), \(coordinate.longitude)")
        DispatchQueue.main.asyncAfter(deadline: .now() + 7 ){
            self.draw2D(latitude: coordinate.latitude, longitude: coordinate.longitude)
        }
    }
    
    @objc func saveToSever () {

        // MARK: Save to sever
        if saveLocation == true {
            let latitude = saveLatitude
            let longitude = saveLongitude
            self.communicator.updateUserLocation(latitude: latitude, longitude: longitude)
            { (result, error) in
                if let error = error {
                    print("Save coordinate to server error : \(error)")
                    return
                }
                print("Save coordinate to server OK: \(result!)")
            }
            // Auto show position between friends and user on same screen
            self.moveAndZoomMap()
        }else {
            return
        }
    }
    
    @objc func saveToLocalDataBase() {
        // Save to localDataBase
        self.locationManager.coodinateAppend(lat: saveLatitude, lon: saveLongitude)
    }
    
    func draw2D(latitude: Double , longitude: Double ) {
        newPoint = CLLocationCoordinate2D(latitude: latitude , longitude: longitude)
        
        if (lastPoint == nil) {
            lastPoint = newPoint;
        }
        
        let sourceLocation = lastPoint
        let destinationLocation = newPoint

        let sourcePlaceMark = MKPlacemark(coordinate: sourceLocation!)
        let destinationPlaceMark = MKPlacemark(coordinate: destinationLocation!)
        
        let directionRequest = MKDirections.Request()
        directionRequest.source = MKMapItem(placemark: sourcePlaceMark)
        directionRequest.destination = MKMapItem(placemark: destinationPlaceMark)
        directionRequest.transportType = .walking
        
        let directions = MKDirections(request: directionRequest)
        directions.calculate { (response, error) in
            guard let directionResonse = response else {
                if let error = error {
                    print("we have error getting directions==\(error.localizedDescription)")
                }
                return
            }
        let route = directionResonse.routes[0]
        self.mainMapView.addOverlay(route.polyline, level: .aboveRoads)
        let rect = route.polyline.boundingMapRect
        self.mainMapView.setRegion(MKCoordinateRegion(rect), animated: true)
        }
        lastPoint = newPoint
    }
    
    func doRefreshJob(){
        
        // 當retriveMessages 重複呼叫時.
        communicator.queryFriendLocations { (result, error) in
            
            if let error = error {
                print("Get queryFriendLocations error : \(error)")
                return
            }
            print("Send queryFriendLocations OK: \(result!)")
            
            // Decode as [friends]. // 10/26新增
            guard let jsonData = try? JSONSerialization.data(withJSONObject: result as Any, options: .prettyPrinted) else{
                print("Fail to generate jsonData.")
                return
            }
            let decoder = JSONDecoder()
            guard let resultObject = try? decoder.decode(RetriveResult.self, from: jsonData) else{
                print("Fail to decode jsonData.")
                return
            }
            print("resultObject: \(resultObject)")
            guard let friends = resultObject.friends, !friends.isEmpty else{
                print("friends is nil or empty.")
                return
            }
            self.friends = friends
            self.view.reloadInputViews()
        }
    }
    
    func getLocalCoordinate(){

        let startIndex: Int = {
            var result = locationManager.count - 20
            if result < 0 {
                result = 0
            }
            return result
        }()
        for i in 0..<(locationManager.count - startIndex){
            guard let location = locationManager.getLocation(at: startIndex + i) else{
                assertionFailure("Fail to get message from logManager.")
                continue
            }
            localCoordinate.append(location)
        }
        doRefreshJob()
        // get the localCoordinate 20 data before now.
        let localData = localCoordinate.prefix(20)
        
        for localCoordinate in localData{
            draw2D(latitude: Double(localCoordinate.lat)!, longitude: Double(localCoordinate.lon)!)
            print("draw2D: \(localCoordinate.lat),\(localCoordinate.lon)")
        }
    }
}



//Protocol 利用.
class StoreAnnotation :NSObject, MKAnnotation{
    //Basic properties
    var coordinate: CLLocationCoordinate2D = CLLocationCoordinate2DMake(0, 0) //語法上要給予起始值.
    var title : String?
    var subtitle: String?
    
    override init(){
        super.init()
        
    }
    
}
