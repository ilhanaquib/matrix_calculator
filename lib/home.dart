import 'package:flutter/material.dart';

class NutrientSolverHome extends StatefulWidget {
  const NutrientSolverHome({super.key});

  @override
  State<NutrientSolverHome> createState() => _NutrientSolverHomeState();
}

class _NutrientSolverHomeState extends State<NutrientSolverHome>
    with SingleTickerProviderStateMixin {
  // rows and columns for the table / matrix
  final List<String> rows = ['Calories', 'Protein', 'Fat'];
  final List<String> columns = ['Dish 1', 'Dish 2', 'Dish 3'];

  // controllers
  final List<List<TextEditingController>> nutrientControllers = List.generate(
    3,
    (_) => List.generate(3, (_) => TextEditingController()),
  );
  final List<TextEditingController> targetControllers = List.generate(
    3,
    (_) => TextEditingController(),
  );
  final List<TextEditingController> servingSizeControllers = List.generate(
    3,
    (_) => TextEditingController(),
  );

  // minimun grams
  List<double> dishGrams = [100.0, 100.0, 100.0];

  // result output variable
  String result = '';

  // tab controller to switch tabs (solve linear equation or inverse matrix)
  late TabController tabController;

  // init method
  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 2, vsync: this);
  }

  // dispose method
  @override
  void dispose() {
    for (var row in nutrientControllers) {
      for (var controller in row) {
        controller.dispose();
      }
    }
    for (var c in targetControllers) {
      c.dispose();
    }
    for (var c in servingSizeControllers) {
      c.dispose();
    }
    tabController.dispose();
    super.dispose();
  }

  // formatter (adds + and g)
  String formatAdjustment(double grams) {
    return (grams >= 0
        ? '+${grams.toStringAsFixed(2)} g'
        : '${grams.toStringAsFixed(2)} g');
  }

  // method used to calculate the user input
  void calculate() {
    // create 3x3 matrix
    List<List<double>> perGramMatrix = List.generate(
      3,
      (_) => List.filled(3, 0.0),
    );

    // used for target matrix
    List<double> targetVector = List.filled(3, 0.0);
    // used for serving size matrix
    List<double> servingSizes = List.filled(3, 0.0);

    // parse user target nutrients
    for (int i = 0; i < 3; i++) {
      targetVector[i] = double.tryParse(targetControllers[i].text) ?? 0.0;
    }

    // calculate per-gram by dividing total nutrients with serving size
    for (int j = 0; j < 3; j++) {
      double serving = double.tryParse(servingSizeControllers[j].text) ?? 1.0;
      servingSizes[j] = serving;
      for (int i = 0; i < 3; i++) {
        double total = double.tryParse(nutrientControllers[i][j].text) ?? 0.0;
        perGramMatrix[i][j] = total / serving;
      }
    }

    // if a row of all zeroes can't satisfy a non-zero target, return error
    if (!isFeasible(perGramMatrix, targetVector)) {
      setState(() {
        result = 'Infeasible nutrient target based on current dish data.';
      });
      return;
    }

    // calls the solveLinearEquation to solve via Gaussian Elimination
    List<double>? grams = solveLinearEquation(3, 4, [
      [...perGramMatrix[0], targetVector[0]],
      [...perGramMatrix[1], targetVector[1]],
      [...perGramMatrix[2], targetVector[2]],
    ]);

    // if there is no unique solution
    if (grams == null) {
      setState(() {
        result = 'No unique solution found.';
      });
      return;
    }

    // if there is a solution, return this to user
    setState(() {
      result = '''
Recommended Portion Adjustments:
- Dish 1: ${formatAdjustment(grams[0])}
- Dish 2: ${formatAdjustment(grams[1])}
- Dish 3: ${formatAdjustment(grams[2])}

*Negative = reduce from current portion
''';
    });
  }

  // method used to solve linear equation via gaussian elimination
  List<double>? solveLinearEquation(
    int rows,
    int cols,
    List<List<double>> matrix,
  ) {
    int variables = cols - 1;

    // forward elimination
    for (int pivot = 0; pivot < rows; pivot++) {
      if (matrix[pivot][pivot] == 0) {
        for (int i = pivot + 1; i < rows; i++) {
          if (matrix[i][pivot] != 0) {
            var temp = matrix[pivot];
            matrix[pivot] = matrix[i];
            matrix[i] = temp;
            break;
          }
        }
      }

      // eliminate below pivot
      for (int i = pivot + 1; i < rows; i++) {
        double factor = matrix[i][pivot] / matrix[pivot][pivot];
        for (int j = pivot; j < cols; j++) {
          matrix[i][j] -= factor * matrix[pivot][j];
        }
      }
    }

    List<double> solution = List.filled(variables, 0);

    // back substitution
    for (int i = variables - 1; i >= 0; i--) {
      double sum = matrix[i][variables];
      for (int j = i + 1; j < variables; j++) {
        sum -= matrix[i][j] * solution[j];
      }
      solution[i] = sum / matrix[i][i];
    }

    // solution
    return solution;
  }

  // inverse the matrix
  List<List<double>>? inverseMatrix(List<List<double>> matrix) {
    int n = matrix.length;

    // create augment with identitiy matrix
    List<List<double>> augmented = List.generate(n, (i) {
      return List.generate(n * 2, (j) {
        if (j < n) return matrix[i][j];
        return i == j - n ? 1.0 : 0.0;
      });
    });

    // Gaussian elimination
    for (int i = 0; i < n; i++) {
      double pivot = augmented[i][i];
      if (pivot == 0) return null;
      for (int j = 0; j < 2 * n; j++) {
        augmented[i][j] /= pivot;
      }
      for (int k = 0; k < n; k++) {
        if (k == i) continue;
        double factor = augmented[k][i];
        for (int j = 0; j < 2 * n; j++) {
          augmented[k][j] -= factor * augmented[i][j];
        }
      }
    }

    // return result
    return List.generate(n, (i) => augmented[i].sublist(n));
  }

  // Checks whether the target vector is feasible based on the per-gram matrix.
  bool isFeasible(List<List<double>> matrix, List<double> target) {
    for (int i = 0; i < target.length; i++) {
      bool allZero = matrix[i].every((value) => value == 0.0);
      if (allZero && target[i] != 0.0) return false;
    }
    return true;
  }

  // for when sliders are adjusted in Manual Fine-Tune tab.
  void updateCustomizedResult() {
    List<List<double>> perGramMatrix = List.generate(
      3,
      (_) => List.filled(3, 0.0),
    );
    for (int j = 0; j < 3; j++) {
      double serving = double.tryParse(servingSizeControllers[j].text) ?? 1.0;
      for (int i = 0; i < 3; i++) {
        double total = double.tryParse(nutrientControllers[i][j].text) ?? 0.0;
        perGramMatrix[i][j] = total / serving;
      }
    }

    // Calculate total nutrients based on current portion selections
    List<double> totalNutrients = List.filled(3, 0.0);
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        totalNutrients[i] += perGramMatrix[i][j] * dishGrams[j];
      }
    }
    // calculate inverse matrix to estimate ideal portion
    List<List<double>>? inverse = inverseMatrix(perGramMatrix);
    List<double>? solvedGrams =
        inverse != null ? multiplyMatrixVector(inverse, totalNutrients) : null;

    setState(() {
      result = '''
Resulting Nutrients:
- Calories: ${totalNutrients[0].toStringAsFixed(1)} kcal
- Protein: ${totalNutrients[1].toStringAsFixed(1)} g
- Fat: ${totalNutrients[2].toStringAsFixed(1)} g

Inverted Portion Estimate:
- Dish 1: ${solvedGrams != null ? solvedGrams[0].toStringAsFixed(2) : "N/A"} g
- Dish 2: ${solvedGrams != null ? solvedGrams[1].toStringAsFixed(2) : "N/A"} g
- Dish 3: ${solvedGrams != null ? solvedGrams[2].toStringAsFixed(2) : "N/A"} g
''';
    });
  }

  // Multiplies a matrix (n x n) with a vector (n x 1)
  List<double> multiplyMatrixVector(
    List<List<double>> matrix,
    List<double> vector,
  ) {
    return List.generate(matrix.length, (i) {
      double sum = 0.0;
      for (int j = 0; j < vector.length; j++) {
        sum += matrix[i][j] * vector[j];
      }
      return sum;
    });
  }

  // ui
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Macronutrient Trade-off Tool'),
        bottom: TabBar(
          controller: tabController,
          tabs: const [
            Tab(text: 'Auto Adjust Portions'),
            Tab(text: 'Manual Fine-Tune'),
          ],
        ),
      ),
      body: TabBarView(
        controller: tabController,
        children: [
          buildInputUI(isCustomizeMode: false),
          buildInputUI(isCustomizeMode: true),
        ],
      ),
    );
  }

  // custom widget for input ui
  Widget buildInputUI({bool isCustomizeMode = false}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          buildNutrientTable(),
          const SizedBox(height: 16),
          const Text('Serving Sizes (g):'),
          buildServingInputs(),
          const SizedBox(height: 16),
          if (!isCustomizeMode) ...[
            const Text('Target Macronutrients (per meal or day):'),
            buildTargetInputs(),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: calculate,
              child: const Text('Calculate'),
            ),
          ] else ...[
            const Text('Manually Adjust Portions (g):'),
            const Text(
              '*Adjust sliders to see impact on Calories / Protein / Fat',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            ...List.generate(3, (i) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${columns[i]}: ${dishGrams[i].toStringAsFixed(1)} g'),
                  Slider(
                    min: 0,
                    max: 500,
                    divisions: 100,
                    value: dishGrams[i],
                    label: dishGrams[i].toStringAsFixed(1),
                    onChanged: (value) {
                      setState(() {
                        dishGrams[i] = value;
                        updateCustomizedResult();
                      });
                    },
                  ),
                ],
              );
            }),
          ],
          const SizedBox(height: 16),
          Text(result, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  // custom widget for the table
  Widget buildNutrientTable() {
    return Table(
      border: TableBorder.all(),
      defaultColumnWidth: const IntrinsicColumnWidth(),
      children: [
        TableRow(
          children: [
            const TableCell(
              child: Padding(padding: EdgeInsets.all(8), child: Text('')),
            ),
            ...columns.map(
              (col) => TableCell(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(col, textAlign: TextAlign.center),
                ),
              ),
            ),
          ],
        ),
        for (int i = 0; i < 3; i++)
          TableRow(
            children: [
              Padding(padding: const EdgeInsets.all(8), child: Text(rows[i])),
              for (int j = 0; j < 3; j++)
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: TextField(
                    controller: nutrientControllers[i][j],
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: 'Total',
                      border: InputBorder.none,
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }

  // custom widget for serving size input
  Widget buildServingInputs() {
    return Row(
      children: List.generate(3, (i) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: servingSizeControllers[i],
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: columns[i],
                border: const OutlineInputBorder(),
              ),
            ),
          ),
        );
      }),
    );
  }

  // custom widget for target inputs
  Widget buildTargetInputs() {
    return Column(
      children: List.generate(3, (i) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: TextField(
            controller: targetControllers[i],
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: rows[i],
              border: const OutlineInputBorder(),
            ),
          ),
        );
      }),
    );
  }
}
