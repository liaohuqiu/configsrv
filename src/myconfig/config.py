from jinja2 import Environment

def render(patten, data):
    env = Environment(keep_trailing_newline=True)
    patten = patten.decode('utf-8')
    s = env.from_string(patten)
    ret = s.render(data)
    return ret

def load_yaml(file):
    data = None
    with open(file, 'r') as f:
        data = yaml.load(f)
    return data

class Config:

    def __init__(self):
        dir = '/configsrv/config'
        if not os.path.exists(dir):
            raise Exception('The config path: /configsrv/config is not existent, do you forget to mount it?')

        self.config_dir = dir

    def read_config(self, config_content, config_type, config_key):
        config = None
        if config_type == 'yaml':
            config = yaml.load(config_content)
        elif config_type == 'json':
            config = json.load(config_content)
        else:
            raise Exception('This config type is not supported now: ' +  config_type)

        return self._read_config(config, config_key)

    def output(self, data, format):
        if format == 'json':
            return json.dumps(data)
        # default it yaml
        else:
            return yaml.dump(data, default_flow_style=False)

    def read_config_from_local(self, config_file_name, config_key):

        file_name = self.config_dir + '/' + config_file_name + '.yaml'
        if not os.path.isfile(file_name):
            raise Exception('The config file is not existent: ' +  file_name)

        config = load_yaml(file_name)
        return self._read_config(config, config_key)

    def _read_config(self, config, key):
        data = config.copy()
        key_list = key.split('.')
        for sub_key in key_list:
            if sub_key not in data:
                raise Exception('Can not find config section for sub key:' +  sub_key)
            data = data[sub_key]
        return data
