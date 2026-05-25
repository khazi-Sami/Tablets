import Foundation

struct NutritionSuggestion {
    let nutrient: String
    let whyImportant: String
    let foodSources: [String]
    let weekRange: ClosedRange<Int>
    let mealIdeas: [String]
}

struct PregnancyNutritionGuide {
    func getSuggestion(for week: Int, query: String = "") -> String {
        let suggestions = data.filter { $0.weekRange.contains(week) }
        guard !suggestions.isEmpty else {
            return "Try balanced meals with protein, vegetables, whole grains, and water. These are general suggestions only. Please follow your doctor's or dietitian's advice for your specific needs."
        }
        let selected = Array(suggestions.prefix(2))
        let foods = selected.flatMap(\.foodSources).prefix(5).joined(separator: ", ")
        let meals = selected.flatMap(\.mealIdeas).prefix(3).joined(separator: "; ")
        let nutrients = selected.map(\.nutrient).joined(separator: " and ")
        return "At week \(week), \(nutrients) can be helpful pregnancy nutrition topics. Try: \(foods). Meal ideas: \(meals). These are general suggestions only. Please follow your doctor's or dietitian's advice for your specific needs."
    }

    private var data: [NutritionSuggestion] {
        [
            NutritionSuggestion(nutrient: "Folic acid", whyImportant: "Supports your baby's neural tube development.", foodSources: ["Spinach", "Lentils", "Fortified cereals", "Broccoli", "Asparagus"], weekRange: 4...13, mealIdeas: ["Spinach dal with roti", "Lentil soup with whole grain bread", "Broccoli stir fry with rice"]),
            NutritionSuggestion(nutrient: "Vitamin B6", whyImportant: "May help reduce morning sickness.", foodSources: ["Bananas", "Ginger", "Crackers", "Chicken", "Potatoes"], weekRange: 4...13, mealIdeas: ["Banana with a few crackers", "Ginger tea with dry toast", "Boiled potato with light seasoning"]),
            NutritionSuggestion(nutrient: "Calcium", whyImportant: "Supports baby's developing bones and teeth.", foodSources: ["Milk", "Yogurt", "Paneer", "Almonds", "Sesame seeds", "Ragi"], weekRange: 14...27, mealIdeas: ["Ragi porridge with milk", "Paneer bhurji with roti", "Yogurt with fruit and almonds"]),
            NutritionSuggestion(nutrient: "Iron", whyImportant: "Supports increased blood volume and helps prevent anaemia.", foodSources: ["Spinach", "Dates", "Pomegranate", "Lentils", "Jaggery", "Beetroot"], weekRange: 14...27, mealIdeas: ["Palak dal", "Date and nut energy balls", "Beetroot sabzi with roti"]),
            NutritionSuggestion(nutrient: "Protein", whyImportant: "Essential for baby's growth and tissue development.", foodSources: ["Eggs", "Chicken", "Fish", "Paneer", "Lentils", "Chickpeas", "Tofu"], weekRange: 14...27, mealIdeas: ["Egg bhurji with toast", "Chickpea curry with rice", "Tofu stir fry with quinoa"]),
            NutritionSuggestion(nutrient: "DHA / Omega-3", whyImportant: "Supports baby's brain and eye development.", foodSources: ["Walnuts", "Flaxseed", "Fish", "Chia seeds"], weekRange: 28...40, mealIdeas: ["Walnut and date snack", "Flaxseed added to dal or roti", "Fish curry with brown rice"]),
            NutritionSuggestion(nutrient: "Fibre", whyImportant: "Helps with constipation common in late pregnancy.", foodSources: ["Oats", "Whole grains", "Fruits", "Vegetables", "Legumes"], weekRange: 28...40, mealIdeas: ["Oats porridge with banana", "Mixed vegetable soup", "Fruit chaat"])
        ]
    }
}
