//
//  ContentView.swift
//  Lab2
//
//  Created by Volodymyr on 18.09.2025.
//

import SwiftUI


enum FuelType: String {
    case petrol = "Бензин"
    case diesel = "Дизель"
    case electric = "Електро"
}

struct Car {
    var brand: String
    var model: String?
    var mileage: Double?
    var fuelType: FuelType
    
    func describe() -> String {
        var description = "Марка: \(brand)"
        description += ", Модель: \(model ?? "невідома")"
        description += ", Пробіг: \(mileage != nil ? "\(mileage!) км" : "невідомий")"
        description += ", Паливо: \(fuelType.rawValue)"
        return description
    }
}

class Driver {
    var name: String
    var car: Car?
    
    init(name: String, car: Car? = nil) {
        self.name = name
        self.car = car
    }
    
    func showCarInfo() -> String {
        if let car = car {
            return "Водій: \(name)\n\(car.describe())"
        } else {
            return "Водій: \(name)\nНемає автомобіля"
        }
    }
}

struct ContentView: View {
    let cars = [
        Car(brand: "Toyota", model: "Camry", mileage: 25000, fuelType: .petrol),
        Car(brand: "Tesla", model: "Model S", mileage: nil, fuelType: .electric),
        Car(brand: "BMW", model: nil, mileage: 120000, fuelType: .diesel),
        Car(brand: "Peugeot", model: "308 sw", mileage: 170956, fuelType: .petrol)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Список автомобілів")
                .font(.title)
                .padding(.bottom, 10)
            
            ForEach(0..<cars.count, id: \.self) { i in
                Text(cars[i].describe())
            }
            
            Divider().padding(.vertical, 10)
            
            let driver1 = Driver(name: "Андрій", car: cars[0])
            let driver2 = Driver(name: "Олег", car: nil)
            let driver3 = Driver(name: "Володимир", car: cars[3])
            
            Text(driver1.showCarInfo())
                .padding(.top, 5)
            Text(driver2.showCarInfo())
                .padding(.top, 5)
            Text(driver3.showCarInfo())
                .padding(.top, 5)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
