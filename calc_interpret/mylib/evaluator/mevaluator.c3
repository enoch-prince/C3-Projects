module mylib::evaluator::mevaluator;

import mylib::parser::mparser;
import std::math;

fn double factorial(double x) @private {
    if (x == 0) return 1.00;
    return x * factorial(x-1);
}

fn double! mevaluate(ASTNode* node) {

    switch (node.type)
    {
        case AST_NUMBER:
            return node.value.to_double()!;
        case AST_UNARY_OP:
            double left = mevaluate(node.left)!;
            switch (node.value) {
                case "+":
                    return left;
                case "-":
                    return -left;
                case "e":
                case "E":
                    return (double)math::exp(left);
                default:
                    break;
            }
        case AST_BINARY_OP:
            double left = mevaluate(node.left)!;
            double right = mevaluate(node.right)!;
            switch (node.value)
            {   
                case "+":
                    return left + right;
                case "-":
                    return left - right;
                case "/":
                    return left / right;
                case "*":
                    return left * right;
                case "%":
                    // ref: https://stackoverflow.com/a/52529440
                    double res = left % right;
                    if (res < 0) {
                        // res += (right < 0) ? -right : right; // avoid this form: it is UB when b == INT_MIN
                        res = (right < 0) ? res - right : res + right;
                    }
                    return res;
                case "^":
                    return (double)math::pow(left, right);
                case "e":
                case "E":
                    return left * (double)math::exp(right);
                default:
                    break;
                
            }
        case AST_FUNCION_CALL:
            double left = mevaluate(node.left)!;
            switch (node.value) {
                case "sin":
                    left = math::deg_to_rad(left);
                    return math::sin(left);
                case "cos":
                    left = math::deg_to_rad(left);
                    return math::cos(left);
                case "tan":
                    left = math::deg_to_rad(left);
                    return math::tan(left);
                case "atan":
                    left = math::deg_to_rad(left);
                    return math::atan(left);
                case "atan2":
                    unreachable("atan2 unimplemented");
                case "sqrt":
                    return math::sqrt(left);
                case "!":
                    return factorial(left);
                default:
                    break;
            }

        default:
            break;
        
    }

    return 0.00;
}