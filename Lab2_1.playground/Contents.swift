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
    var trunkVolume: Double
    
    func describe() -> String {
        var description = "Марка: \(brand)"
        description += ", Модель: \(model ?? "невідома")"
        description += ", Пробіг: \(mileage != nil ? "\(mileage!) км" : "невідомий")"
        description += ", Паливо: \(fuelType.rawValue)"
        description += ", Об'єм багажнику: \(trunkVolume) л"
        return description
    }
}

func describeCar(car: Car) {
    var description = "Марка: \(car.brand)"
    description += ", Модель: \(car.model ?? "невідома")"
    description += ", Пробіг: \(car.mileage != nil ? "\(car.mileage!) км" : "невідомий")"
    description += ", Паливо: \(car.fuelType.rawValue)"
    description += ", Об'єм багажнику: \(car.trunkVolume) л"
    print(description)
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


let cars = [
    Car(brand: "Toyota", model: "Camry", mileage: 25000, fuelType: .petrol, trunkVolume: 150),
    Car(brand: "Tesla", model: "Model S", mileage: nil, fuelType: .electric, trunkVolume: 210),
    Car(brand: "BMW", model: nil, mileage: 120000, fuelType: .diesel,trunkVolume: 120),
    Car(brand: "Peugeot", model: "308 SW", mileage: 171327, fuelType: .petrol,trunkVolume: 412)
]

let driver1 = Driver(name: "Андрій", car: cars[0])
let driver2 = Driver(name: "Олег", car: nil)
let driver3 = Driver(name: "Володимир", car: cars[3])

print("Список автомобілів:")
for car in cars {
    print(car.describe())
}

print("\nІнформація про водіїв:")
print(driver1.showCarInfo())
print(driver2.showCarInfo())
print(driver3.showCarInfo())
