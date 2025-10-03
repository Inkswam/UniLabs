import UIKit

class ViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    
    // MARK: - IBOutlets
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var brandTextField: UITextField!
    @IBOutlet weak var modelTextField: UITextField!
    @IBOutlet weak var yearTextField: UITextField!
    @IBOutlet weak var colorTextField: UITextField!
    @IBOutlet weak var numberPlateTextField: UITextField!
    @IBOutlet weak var ownerNameTextField: UITextField!
    
    @IBOutlet weak var insuranceSwitch: UISwitch!
    @IBOutlet weak var categoryPicker: UIPickerView!
    @IBOutlet weak var saveButton: UIButton!
    
    // MARK: - Data
    let categories = ["A", "B", "C", "D"]
    var selectedCategory: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Picker setup
        categoryPicker.delegate = self
        categoryPicker.dataSource = self
        selectedCategory = categories.first
        
        // UI Setup
        titleLabel.text = "Анкета водія"
        profileImageView.image = UIImage(systemName: "car.fill") 
    }
    
    // MARK: - PickerView Delegates
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return categories.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return categories[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedCategory = categories[row]
    }
    
    // MARK: - Button Action
    @IBAction func saveButtonTapped(_ sender: UIButton) {
        guard let brand = brandTextField.text, !brand.isEmpty,
              let model = modelTextField.text, !model.isEmpty else {
            print("❌ Марка і модель обов’язкові")
            return
        }
        
        let form = DriverForm(
            brand: brand,
            model: model,
            year: yearTextField.text,
            color: colorTextField.text,
            numberPlate: numberPlateTextField.text,
            ownerName: ownerNameTextField.text,
            hasInsurance: insuranceSwitch.isOn,
            category: selectedCategory
        )
        
        // Вивід у консоль
        print("🚗 Анкета водія:")
        print("Марка: \(form.brand)")
        print("Модель: \(form.model)")
        print("Рік: \(form.year ?? "-")")
        print("Колір: \(form.color ?? "-")")
        print("Номер: \(form.numberPlate ?? "-")")
        print("Власник: \(form.ownerName ?? "-")")
        print("Страховка: \(form.hasInsurance ? "Так" : "Ні")")
        print("Категорія: \(form.category ?? "-")")
    }
}
