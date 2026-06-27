import os
import re

lib_dir = 'lib'
import_statement = "import 'package:billy_way/core/widgets/app_loading_animation.dart';\n"

for root, dirs, files in os.walk(lib_dir):
    for file in files:
        if file.endswith('.dart') and file != 'app_loading_animation.dart':
            filepath = os.path.join(root, file)
            with open(filepath, 'r') as f:
                content = f.read()
            
            # Simple replacement for `const CircularProgressIndicator()` and `CircularProgressIndicator(...)`
            # Be careful with `color:` or `strokeWidth:` 
            # We will just replace `CircularProgressIndicator()` or `const CircularProgressIndicator()`
            # We'll also remove `const` before it if it exists.
            
            if 'CircularProgressIndicator' in content:
                # Add import if not there
                if import_statement.strip() not in content:
                    # insert after first import
                    if 'import' in content:
                        first_import = content.find('import')
                        end_of_line = content.find('\n', first_import)
                        content = content[:end_of_line+1] + import_statement + content[end_of_line+1:]
                
                content = re.sub(r'const\s+CircularProgressIndicator\s*\(\)', 'AppLoadingAnimation()', content)
                content = re.sub(r'const\s+Center\(\s*child:\s*CircularProgressIndicator\(\)\)', 'const Center(child: AppLoadingAnimation())', content)
                
                # specific ones
                content = content.replace('const CircularProgressIndicator(color: Colors.white)', 'const AppLoadingAnimation(color: Colors.white)')
                content = content.replace('CircularProgressIndicator(color: AppColors.primary)', 'const AppLoadingAnimation()')
                content = content.replace('CircularProgressIndicator()', 'AppLoadingAnimation()')
                
                with open(filepath, 'w') as f:
                    f.write(content)
                
                print(f"Updated {filepath}")
