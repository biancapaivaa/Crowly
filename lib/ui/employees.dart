import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme.dart';
import '../data/store.dart';
import 'widgets.dart';

class EmployeesPage extends StatefulWidget {
  const EmployeesPage({super.key, required this.store});
  final CrowlyStore store;
  @override
  State<EmployeesPage> createState() => _EmployeesPageState();
}
class _EmployeesPageState extends State<EmployeesPage> {
  final form=GlobalKey<FormState>();
  final name=TextEditingController(), email=TextEditingController(), password=TextEditingController();
  List<Map<String,dynamic>> employees=[];
  bool busy=false, loading=true, hidden=true;
  String? error;
  String generatePassword() {
    const chars='ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789!@#';
    final random=Random.secure();
    return 'Cw9!${List.generate(16, (_) => chars[random.nextInt(chars.length)]).join()}';
  }
  @override
  void initState() {
    super.initState();
    password.text=generatePassword();
    load();
  }
  @override
  void dispose() { name.dispose(); email.dispose(); password.dispose(); super.dispose(); }
  Future<void> load() async {
    if (!widget.store.isAdmin) return;
    try {
      final result=await widget.store.employees();
      if (mounted) setState(() { employees=result; error=null; });
    } catch (_) {
      if (mounted) setState(() => error='Não foi possível carregar a equipe. Confira sua conexão e a configuração dos perfis.');
    } finally { if (mounted) setState(() => loading=false); }
  }
  Future<void> submit() async {
    if (busy || !widget.store.isAdmin || !form.currentState!.validate()) return;
    setState(() {busy=true;error=null;});
    final initialPassword=password.text;
    final address=email.text.trim().toLowerCase();
    try {
      await widget.store.createEmployee(name.text.trim(),address,initialPassword);
      if (!mounted) return;
      name.clear();email.clear();password.text=generatePassword();
      await load();
      if (!mounted || !widget.store.isAdmin) return;
      await showDialog<void>(context: context, builder:(ctx) => AlertDialog(
        title: const Text('Funcionário cadastrado'),
        content: SingleChildScrollView(child: Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[
          SelectableText('E-mail: $address'),
          const SizedBox(height:12),
          const Text('Senha inicial — guarde antes de fechar:'),
          const SizedBox(height:8),
          SelectableText(initialPassword,style:const TextStyle(color:Colors.white,fontWeight:FontWeight.bold)),
          const SizedBox(height:12),
          Text(widget.store.demo ? 'Demonstração: nenhuma conta real foi criada.' : 'Entregue o acesso ao funcionário por um canal privado. Ele pode redefinir a senha no próprio perfil. O cadastro não envia e-mail automaticamente.'),
        ])),
        actions:[
          TextButton(onPressed:() async {
            await Clipboard.setData(ClipboardData(text:'E-mail: $address\nSenha inicial: $initialPassword'));
            if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content:Text('Acesso copiado.')));
          },child:const Text('Copiar acesso')),
          FilledButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Concluir')),
        ],
      ));
    } catch (_) {
      if (mounted) setState(()=>error='Não foi possível cadastrar. Confira se o e-mail já existe e se o SQL de perfis e a função de cadastro foram configurados.');
    } finally {if(mounted)setState(()=>busy=false);}
  }
  Widget field(TextEditingController controller,String label,IconData icon,{bool secret=false}) => TextFormField(
    controller:controller,enabled:!busy,obscureText:secret&&hidden,
    keyboardType:label=='E-mail'?TextInputType.emailAddress:TextInputType.text,
    autocorrect:!secret,enableSuggestions:!secret,
    style:const TextStyle(color:Colors.white),
    maxLength:secret?128:label=='E-mail'?254:100,
    decoration:InputDecoration(labelText:label,prefixIcon:Icon(icon),counterText:'',suffixIcon:secret?IconButton(tooltip:hidden?'Mostrar senha':'Ocultar senha',onPressed:()=>setState(()=>hidden=!hidden),icon:Icon(hidden?Icons.visibility_outlined:Icons.visibility_off_outlined)):null),
    validator:(v){
      if(v==null||v.trim().isEmpty)return 'Preencha este campo.';
      if(label=='E-mail'&&!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v.trim()))return 'Informe um e-mail válido.';
      if(secret&&v.length<12)return 'Use pelo menos 12 caracteres.';
      return null;
    },
  );
  @override
  Widget build(BuildContext context) => AnimatedBuilder(animation:widget.store,builder:(context,_)=>Scaffold(
    appBar:AppBar(title:const Text('Funcionários'),backgroundColor:C.background,foregroundColor:Colors.white),
    body:!widget.store.isAdmin?const AdminOnly():SafeArea(child:Center(child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:520),child:SingleChildScrollView(
      padding:const EdgeInsets.all(20),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
        const Text('Cadastre sua equipe',style:TextStyle(color:Colors.white,fontSize:22,fontWeight:FontWeight.bold)),
        const SizedBox(height:10),
        const Text('Funcionários acessam os eventos, dispositivos e alertas da sua equipe. Relatórios e cadastro de contas são exclusivos do administrador.'),
        if(widget.store.demo) const Padding(padding:EdgeInsets.only(top:12),child:Pill('MODO DEMONSTRAÇÃO')),
        const Section('Novo funcionário'),
        Panel(child:Form(key:form,child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
          field(name,'Nome completo',Icons.person_outline),const SizedBox(height:14),
          field(email,'E-mail',Icons.email_outlined),const SizedBox(height:14),
          field(password,'Senha inicial',Icons.lock_outline,secret:true),
          TextButton(onPressed:busy?null:()=>setState(()=>password.text=generatePassword()),child:const Text('Gerar outra senha')),
          const Pill('Perfil: Funcionário'),const SizedBox(height:16),
          FilledButton.icon(onPressed:busy?null:submit,icon:const Icon(Icons.person_add_alt_1),label:Text(busy?'Cadastrando...':'Cadastrar funcionário')),
        ]))),
        if(error!=null) Padding(padding:const EdgeInsets.only(top:14),child:Text(error!)),
        Section('Equipe (${employees.length})',trailing:IconButton(tooltip:'Atualizar equipe',onPressed:busy?null:load,icon:const Icon(Icons.refresh))),
        if(loading)const Center(child:CircularProgressIndicator())
        else if(employees.isEmpty)const Panel(child:Text('Nenhum funcionário cadastrado ainda.'))
        else ...employees.map((m)=>Padding(padding:const EdgeInsets.only(bottom:10),child:Panel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text(m['full_name']?.toString()??'Funcionário',style:const TextStyle(color:Colors.white,fontWeight:FontWeight.bold,fontSize:16)),
          const SizedBox(height:6),Text(m['email']?.toString()??''),
          const SizedBox(height:8),Pill(m['enabled']==true?'Funcionário ativo':'Conta desativada'),
        ])))),
      ]),
    )))),
  ));
}
