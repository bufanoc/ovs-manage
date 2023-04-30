from flask import Flask, request, jsonify, render_template, redirect, url_for, flash
from flask_wtf import FlaskForm
from wtforms import StringField, FieldList, FormField
import ovn_api

app = Flask(__name__)
app.config['SECRET_KEY'] = 'your_secret_key'

class HostForm(FlaskForm):
    name = StringField('Name')
    ip = StringField('IP')
    mac = StringField('MAC')
    vtep_ip = StringField('VTEP IP')

class ConfigureVXLANForm(FlaskForm):
    hosts = FieldList(FormField(HostForm), min_entries=1)

@app.route('/', methods=['GET', 'POST'])
def index():
    form = ConfigureVXLANForm()

    if form.validate_on_submit():
        hosts = [{'name': h.name.data, 'ip': h.ip.data, 'mac': h.mac.data, 'vtep_ip': h.vtep_ip.data} for h in form.hosts.data]
        try:
            ovn = ovn_api.OvnApi()
            ovn.configure_vxlan(hosts)
            flash('VXLAN overlays configured successfully', 'success')
            return redirect(url_for('index'))
        except Exception as e:
            flash(str(e), 'error')
            return redirect(url_for('index'))

    return render_template('index.html', form=form)

@app.route('/configure_vxlan', methods=['POST'])
def configure_vxlan_api():
    data = request.get_json()

    if not data or not 'hosts' in data:
        return jsonify({"error": "Invalid input"}), 400

    hosts = data['hosts']

    try:
        ovn = ovn_api.OvnApi()
        ovn.configure_vxlan(hosts)
        return jsonify({"success": "VXLAN overlays configured successfully"}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    app.run()
 
