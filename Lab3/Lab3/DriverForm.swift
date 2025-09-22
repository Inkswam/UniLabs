import Foundation

class DriverForm {
    var brand: String
    var model: String
    var year: String?
    var color: String?
    var numberPlate: String?
    var ownerName: String?
    var hasInsurance: Bool
    var category: String?
    
    init(brand: String, model: String, year: String?, color: String?, numberPlate: String?, ownerName: String?, hasInsurance: Bool, category: String?) {
        self.brand = brand
        self.model = model
        self.year = year
        self.color = color
        self.numberPlate = numberPlate
        self.ownerName = ownerName
        self.hasInsurance = hasInsurance
        self.category = category
    }
}
