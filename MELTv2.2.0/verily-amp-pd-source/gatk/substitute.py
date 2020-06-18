import argparse
from jinja2 import Template

def main():
  parser = argparse.ArgumentParser(description='Perform substitutions')
  parser.add_argument('--template-file', required=True,
                      help='The template file to substitute into')
  parser.add_argument('--variables', required=True, nargs='*', default=[],
                      help='Variables to substitute', metavar='KEY=VALUE')
  args = parser.parse_args()

  variables = {}
  for var in args.variables:
    key, value = var.split('=', 1)
    variables[key] = value

  with open(args.template_file, 'r') as f:
    template = Template(f.read())
    print(template.render(variables))

if __name__ == '__main__':
  main()

