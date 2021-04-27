//
//  ViewController.swift
//  ESLO Finder
//
//  Created by Matt Gaidica on 4/26/21.
//
//https://stackoverflow.com/questions/25449469/show-current-location-and-update-location-in-mkmapview-in-swift/49191349#49191349
//https://betterprogramming.pub/how-to-customize-mapkit-annotations-baad32487a7
//https://medium.com/@hashemi.eng1985/map-view-does-not-show-all-annotations-at-first-9789d77f6a3a

import UIKit
import MapKit
import CoreLocation
import CoreBluetooth


class ViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var PlayButton: UIButton!
    @IBOutlet weak var RSSILabel: UILabel!
    @IBOutlet weak var ScanLabel: UILabel!
    @IBOutlet weak var WifiButton: UIButton!
    @IBOutlet weak var MapCountLabel: UILabel!
    
    let locationManager = CLLocationManager()
    private var centralManager: CBCentralManager!
    private var peripheral: CBPeripheral!
    var isScanning: Bool = false
    var ScanTimer = Timer()
    var ScanCount: Int = 0
    var ScanTimeout: Int = 5
    var MapCount: Int = 0
    var curRSSI: Int = 0
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.locationManager.requestAlwaysAuthorization()

        // For use in foreground
        self.locationManager.requestWhenInUseAuthorization()

        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.startUpdatingLocation()
        }

        mapView.delegate = self
        mapView.mapType = .standard
        mapView.isZoomEnabled = true
        mapView.isScrollEnabled = true
        mapView.userTrackingMode = .followWithHeading

        if let coor = mapView.userLocation.location?.coordinate{
            mapView.setCenter(coor, animated: true)
        }
        
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    @IBAction func ScanButtonPress(_ sender: Any) {
        if isScanning {
            isScanning = false
            ScanCount = 0
            RSSILabel.text = "N/C"
            curRSSI = 0
            centralManager?.stopScan()
            ScanLabel.text = "Not scanning"
            self.ScanTimer.invalidate()
        } else {
            isScanning = true
            self.mapView.removeAnnotations(self.mapView.annotations)
            ScanLabel.text = "Scanning..."
            self.ScanTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
                self.ScanCount += 1
                if self.ScanCount >= self.ScanTimeout {
                    self.RSSILabel.text = "N/C"
                    self.curRSSI = 0
                }
                
                UIView.animate(withDuration: 0.2,
                    animations: {
                        self.WifiButton.transform = CGAffineTransform(scaleX: 1.4, y: 1.4)
                    },
                    completion: { _ in
                        UIView.animate(withDuration: 0.2) {
                            self.WifiButton.transform = CGAffineTransform.identity
                        }
                    })
                self.centralManager.scanForPeripherals(withServices: [ESLOPeripheral.ESLOServiceUUID],
                                                      options: [CBCentralManagerScanOptionAllowDuplicatesKey : false])
            }
        }
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("Central state update")
    }
    
    // Handles the result of the scan
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        self.centralManager.stopScan()
        self.ScanCount = 0
        curRSSI = RSSI.intValue
        let str : String = RSSI.stringValue
        RSSILabel.text = str + "dB"
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let locValue:CLLocationCoordinate2D = manager.location!.coordinate

        mapView.mapType = MKMapType.satellite
        let viewRegion = MKCoordinateRegion(center: locValue, latitudinalMeters: 50, longitudinalMeters: 50)
        mapView.setRegion(viewRegion, animated: false)
        
        if isScanning {
            let annotation = MKPointAnnotation()
            annotation.coordinate = locValue
            mapView.addAnnotation(annotation)
            MapCount += 1
            MapCountLabel.text = String(MapCount)
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation.isEqual(mapView.userLocation) {
            let view = MKAnnotationView(annotation: annotation, reuseIdentifier: "userLocation")
            let image = UIImage(systemName: "record.circle")
            view.image = image
            return view
        } else {
            let absRSSI = abs(curRSSI)
            var view = mapView.dequeueReusableAnnotationView(withIdentifier: "reuseIdentifer") as? MKMarkerAnnotationView
            if view == nil {
                view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: "reuseIdentifer")
                view?.annotation = annotation
            }
            if absRSSI > 0 {
                let floatVal = 1-CGFloat(absRSSI).converting(from: 40...110, to: 0...1)
                view?.alpha = floatVal
                if (absRSSI <= 80) {
                    view?.markerTintColor = .yellow
                } else {
                    view?.markerTintColor = .red
                }
            } else {
                view?.alpha = 0.1
                view?.markerTintColor = .white
            }
            view?.displayPriority = .required
            return view
        }
    }
}
