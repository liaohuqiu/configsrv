import datetime

from django.shortcuts import render
from django.views.generic import TemplateView, View
from django.views.decorators.http import require_http_methods
from django.views.decorators.csrf import csrf_exempt
from django.http import HttpResponse, HttpResponseRedirect

from . import config

def index(request):
    data = {}
    template_name = 'index.html'
    return render(request, template_name, data)

def _process_request(request):
    if 'template_file' not in request.FILES:
        return HttpResponse('missing template file')

    if 'config_key' not in request.POST:
        return HttpResponse('missing config key')

    config_key = request.POST['config_key']
    kv_list = {}
    if 'kv_list[]' in request.POST:
        for item in request.POST.getlist('kv_list[]'):
            if '=' in item:
                k, v = item.split('=')
                kv_list[k] = v

    conf = config.Config()
    if 'config_file' in request.FILES and 'config_type' in request.POST:
        config_content = ''
        config_file = request.FILES['config_file']
        for chunk in config_file.chunks():
            config_content = config_content + chunk
        config_type = request.POST['config_type']
        config_data = conf.read_config(config_content, config_type, config_key)
    elif 'config_file_name' in request.POST:
        config_file_name = request.POST['config_file_name']
        config_data = conf.read_config_from_local(config_file_name, config_key)
    else:
        return HttpResponse('Can not find: (config_file && config_type) || config_file_name')

    patten = ''
    template_file = request.FILES['template_file']
    for chunk in template_file.chunks():
        patten = patten + chunk

    config_data.update(kv_list)
    ret = config.render(patten, config_data)
    return HttpResponse(ret)

@csrf_exempt
@require_http_methods(["POST"])
def render_config(request):
    try:
        ret = _process_request(request)
        return ret
    except Exception as error:
        response = HttpResponse()
        response.status_code = 404
        response.write(error)
        return response

def get_config(request):

    if 'config_file_name' not in request.GET:
        return HttpResponse('missing config_file_name')

    if 'config_key' not in request.GET:
        return HttpResponse('missing config_key')

    # default it yaml
    format = 'yaml'
    if 'format' in request.GET:
        format = request.GET['format']

    config_key = request.GET['config_key']
    config_file_name = request.GET['config_file_name']

    conf = config.Config()
    config_data = conf.read_config_from_local(config_file_name, config_key)
    ret = conf.output(config_data, format)
    return HttpResponse(ret)
