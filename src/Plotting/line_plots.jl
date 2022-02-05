gr()
using LaTeXStrings
using Plots.Measures

default(label="", grid=true, gridalpha=0.15)

function plot_emissions(m::ClimateModel)
    p = plot(title="net greenhouse gas emissions")
    plot!(p, t(m), effective_emissions(m, M=true), fillrange = effective_emissions(m), alpha=0.25, color=:royalblue1, label="Mitigation");
    plot!(p, t(m), effective_emissions(m, M=true, R=true), fillrange = effective_emissions(m, M=true), alpha=0.25, color=:darkorange, label="CDR");

    plot!(p, t(m), effective_emissions(m), linecolor=:gray, linewidth=2.0, label=L"$q$ (no-policy baseline)")
    plot!(p, t(m), effective_emissions(m, M=true), linecolor=:gray, linewidth=1., linealpha=0.4, label="")
    plot!(p, t(m), effective_emissions(m, M=true, R=true), linecolor=:black, linewidth=2., label=L"$q(1-M) - q_{0}R$ (controlled)")
    plot!(p, t(m), zeros(size(t(m))), linestyle=:dash, linewidth=1.5, linecolor=:gray, alpha=0.75, label="")

    ylimit = maximum(abs.(effective_emissions(m))) * 1.1
    plot!(p, xlims = (t(m)[1],2200.), ylims = (-ylimit, ylimit))
    plot!(p, ylabel = L"effective CO$_{2e}$ emissions [ppm / yr]", xlabel="year")
    plot!(p, xticks = t(m)[1]:40.:2200.)
    plot!(p, legend=:bottomleft)
    return p
end

function plot_concentrations(m::ClimateModel)
    p = plot(title = "greenhouse gas concentrations")
    plot!(p, t(m), c(m), fillrange = c(m, M=true), color=:royalblue1, alpha=0.25, label="Mitigation")
    plot!(p, t(m), c(m, M=true), fillrange = c(m, M=true, R=true), color=:darkorange, alpha=0.25, label="CDR")
    plot!(p, t(m), c(m), color=:gray,  linewidth=2.0, label=L"$c$ (no-policy baseline)")
    plot!(p, t(m), c(m, M=true),color=:black,  linewidth=1, alpha=0.4, label="")
    plot!(p, t(m), c(m, M=true, R=true),color=:black,  linewidth=2.0, label=L"$c_{M,R}$ (controlled)")
    ylims = [0., maximum(c(m))*1.05]
    plot!(p, ylabel=L"CO$_{2e}$ concentration [ppm]", xlabel="year")
    plot!(p, xlim=(t(m)[1],2200.), ylim=ylims, xticks=t(m)[1]:40.:2200.)
    plot!(p, legend=:topleft)
    return p
end

function plot_forcings(m::ClimateModel; F0=3.)
    p = plot(title="forcing (greenhouse effect and SRM)")
    plot!(p, t(m), F(m, F0=F0), fillrange = F(m, M=true, F0=F0), color=:royalblue1, alpha=0.25, label="Mitigation")
    plot!(p, t(m), F(m, M=true, F0=F0), fillrange = F(m, M=true, R=true, F0=F0), color=:darkorange, alpha=0.25, label="CDR")
    plot!(p, t(m), F(m, M=true, R=true, F0=F0), fillrange = F(m, M=true, R=true, G=true, F0=F0), color=:firebrick, alpha=0.25, label="SRM")
    plot!(p, t(m), F(m, F0=F0), color=:gray,  linewidth=2.0, label=L"$F$ (no-policy baseline)")
    plot!(p, t(m), F(m, M=true, F0=F0), color=:black,  linewidth=1, alpha=0.4, label="")
    plot!(p, t(m), F(m, M=true, R=true, F0=F0), color=:black,  linewidth=1, alpha=0.4, label="")
    plot!(p, t(m), F(m, M=true, R=true, G=true, F0=F0), color=:black,  linewidth=2.0, label=L"$F_{M,R,G}$ (controlled)")
    ylims = [0., maximum(F(m, F0=F0))*1.05]
    plot!(p, ylabel=L"radiative forcing [W/m$^{2}$]", xlabel="year")
    plot!(p, xlim=(t(m)[1],2200.), ylim=ylims, xticks=t(m)[1]:40.:2200.)
    plot!(p, legend=:topleft)
    return p
end

function plot_temperatures(m::ClimateModel; temp_goal=1.2)
    p = plot(title="adaptive temperature change")
    plot!(p, t(m), T_adapt(m), fillrange = T_adapt(m, M=true), color=:royalblue1, alpha=0.25, label="Mitigation")
    plot!(p, t(m), T_adapt(m, M=true), fillrange = T_adapt(m, M=true, R=true), color=:darkorange, alpha=0.25, label="CDR")
    plot!(p, t(m), T_adapt(m, M=true, R=true), fillrange = T_adapt(m, M=true, R=true, G=true), color=:firebrick, alpha=0.25, label="SRM")
    plot!(p, t(m), T_adapt(m, M=true, R=true, G=true), fillrange = T_adapt(m, M=true, R=true, G=true, A=true), color=:forestgreen, alpha=0.25, label="Adaptation")
    plot!(p, t(m), T_adapt(m), color=:gray,  linewidth=2.0, label=L"$T$ (no-policy baseline)")
    plot!(p, t(m), T_adapt(m, M=true), color=:black,  linewidth=1, alpha=0.4, label="")
    plot!(p, t(m), T_adapt(m, M=true, R=true), color=:black,  linewidth=1, alpha=0.4, label="")
    plot!(p, t(m), T_adapt(m, M=true, R=true, G=true), color=:black,  linewidth=1., alpha=0.4, label="")
    plot!(p, t(m), T_adapt(m, M=true, R=true, G=true, A=true), color=:black,  linewidth=2.0, label=L"$T_{M,R,G,A}$ (adaptive)")
    plot!(p, t(m), temp_goal .* ones(size(t(m))), linestyle=:dash, color=:gray, alpha=0.75,  linewidth=2.5, label="")
    ylims = [0., maximum(T_adapt(m)) * 1.05]
    plot!(p, ylabel="temperature anomaly [°C]", xlabel="year")
    plot!(p, xlim=(t(m)[1],2200.), xticks=t(m)[1]:40.:2200., ylim=ylims)
    plot!(p, legend=:topleft)
    return p
end

function plot_controls(m::ClimateModel)
    p = plot(title="optimized control deployments")
    plot!(p, t(m)[m.economics.baseline_emissions .> 0.], m.controls.mitigate[m.economics.baseline_emissions .> 0.],
        color=:royalblue1,  linewidth=2.5, label=L"$M$ (emissions mitigation)")
    plot!(p, t(m), m.controls.remove, color=:darkorange,  linewidth=2.5, label=L"$R$ (carbon dioxide removal)")
    plot!(p, t(m), m.controls.adapt, color=:forestgreen,  linewidth=2.5, label=L"$A$ (adaptation)")
    plot!(p, t(m), m.controls.geoeng, color=:firebrick,  linewidth=2.5, label=L"$G$ (solar geoengineering)")
    ylims = [0., 1.075]
    plot!(p, yticks=0.:0.2:1.0, yticklabels=0:20:100, xticks=t(m)[1]:40.:2200.)
    plot!(p, ylim=ylims, xlim=(t(m)[1],2200.))
    plot!(p, xlabel="year", ylabel="control deployment [%]")
    plot!(p, legend=:topleft)
    return p
end

function plot_benefits(m::ClimateModel; discounting=true)
    domain_idx = (t(m) .> m.domain.present_year)

    p = plot(title="cost-benefit analysis")
    plot!(p, 
        t(m)[domain_idx],
        0 .*ones(size(t(m)))[domain_idx],
        fillrange = net_benefit(m, discounting=discounting, M=true, R=true, G=true, A=true)[domain_idx],
        color=:gray, alpha=0.15, label=""
    )
    plot!(p, t(m)[domain_idx], 0 .*ones(size(t(m)))[domain_idx],  linewidth=2, color=:gray, label="no-policy baseline")
    plot!(p, t(m)[domain_idx], benefit(m, discounting=discounting, M=true, R=true, G=true, A=true)[domain_idx], color=:olive,  linewidth=2, label="benefits (of avoided damages)")
    plot!(p, t(m)[domain_idx], cost(m, discounting=discounting, M=true, R=true, G=true, A=true)[domain_idx], color=:purple,  linewidth=2, label="costs (of climate controls)")
    plot!(p, t(m)[domain_idx], net_benefit(m, discounting=discounting, M=true, R=true, G=true, A=true)[domain_idx], color=:black,  linewidth=2, label="net benefits (benefits - costs)")
    plot!(p, ylabel=L"discounted costs and benefits [10$^{12}$ \$ / year]", xlabel="year")
    plot!(p, xlim=(t(m)[1],2200.), xticks=t(m)[1]:40.:2200.)
    plot!(p, legend=:topleft)
    return p
end

function plot_damages(m::ClimateModel; discounting=true, percent_GWP=false, temp_goal=1.2)
    p = plot(title="costs of avoiding a damage threshold")

    Enorm = deepcopy(E(m))/100.
    if ~percent_GWP; Enorm=1.; end;

    domain_idx = (t(m) .> m.domain.present_year)
    plot!(p, 
        t(m)[domain_idx],
        0 .*ones(size(t(m)))[domain_idx],
        fillrange = (cost(m, discounting=discounting, M=true, R=true, G=true, A=true) ./ Enorm)[domain_idx],
        color=:purple, alpha=0.2, label=""
    )
    damages = damage(m, discounting=discounting, M=true, R=true, G=true, A=true)
    costs = cost(m, discounting=discounting, M=true, R=true, G=true, A=true)
    plot!(p, t(m)[domain_idx], (damage(m, discounting=discounting) ./ Enorm)[domain_idx], color=:gray,  linewidth=2.0, label="uncontrolled damages")
    plot!(p, t(m)[domain_idx], ((damages .+ costs)./ Enorm)[domain_idx], color=:black,  linewidth=2.0, label="net costs (controlled damages + controls)")
    plot!(p, t(m)[domain_idx], (damages ./ Enorm)[domain_idx], color=:olive,  linewidth=2.0, label="controlled damages")
    plot!(p, t(m)[domain_idx], (costs ./ Enorm)[domain_idx], color=:purple,  linewidth=2.0, label="cost of controls")

    ylims=(0, maximum((damage(m, discounting=discounting) ./ Enorm)[domain_idx]) * 0.75)
    
    dmg_label = string("damage threshold at ",round(temp_goal, digits=2),L"°C with $A=0$")
    plot!(
        t(m)[domain_idx],
        (damage(m.economics.β, E(m), temp_goal, discount=discount(m)) ./ Enorm)[domain_idx],
        linestyle=:dash, color=:gray, alpha=0.75, linewidth=2.0, label=dmg_label
    )

    if ~percent_GWP;
        if ~discounting;
            ylabel=L"costs [10$^{12}$ \$ / year]";
        else;
            ylabel=L"discounted costs [10$^{12}$ \$ / year]";
        end
    else
        if ~discounting
            ylabel="costs [% GWP]"
        else
            ylabel="discounted costs [% GWP]"
            print("NOT YET SUPPORTED")
        end
    end
    plot!(p, xlabel="year", ylabel=ylabel)
    plot!(p, xlim=(t(m)[1],2200.), ylim=ylims, xticks=t(m)[1]:40.:2200.)
    plot!(p, legend=:topleft)
    return p
end

function plot_state(m::ClimateModel; temp_goal=1.2)
    l = @layout [
        a b c;
        d e f
    ]
    p = plot(
        size=(1600, 800),
        margin=5mm,
        leftmargin=10mm,
        plot_emissions(m),
        plot_concentrations(m),
        plot_temperatures(m, temp_goal=temp_goal),
        plot_controls(m),
        plot_benefits(m),
        plot_damages(m, temp_goal=temp_goal),
    )
    return p
end
